# Core azure resources: RG, ACR, AKS, Module(VNET, Subnet), Redis_cache, Cosmos_DB_for_MongoDB

locals {
  suffix               = random_string.random.result
  service_account_name = "app-sa"
  namespace            = "app"
}

resource "random_string" "random" {
  length  = 4
  lower   = true
  numeric = true
  upper   = false
  special = false
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create a virtual network and subnets
module "vnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"

  name                = "vnet-${var.project_name}-${local.suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  # Private Endpoints, securely access a public Azure PaaS service (like ACR) from your private network through azure private link and private DNS
  subnets = {
    "aks" = {
      name                              = "subnet1 for aks"
      address_prefixes                  = ["10.0.0.0/24"]
      private_endpoint_network_policies = "Enabled"
    }
    "app" = {
      name                              = "subnet2 for apps"
      address_prefixes                  = ["10.0.1.0/24"]
      private_endpoint_network_policies = "Disabled" # to prevent policies from affecting Private Endpoints
    }
    # dedicated subnet for all Private Endpoints
    "private-endpoints" = {
      name                              = "subnet3 for private-endpoints services"
      address_prefixes                  = ["10.0.2.0/24"]
      private_endpoint_network_policies = "Disabled" # to prevent policies from affecting Private Endpoints
    }
  }
}

# create ACR to store the images
resource "azurerm_container_registry" "acr" {
  name                          = "acr${replace(var.project_name, "-", "")}${local.suffix}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  sku                           = var.acr_sku
  admin_enabled                 = false
  public_network_access_enabled = false
  tags = {
    Environment = "Production"
  }
}

# create AKS cluster with default node pool
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.project_name}-${local.suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks-${var.project_name}-${local.suffix}" # It creates a fully qualified domain name for the Kubernetes API Server, azure gives you a public endpoint so you can manage the cluster using kubectl

  # This pool for cluster core pods like kube-system.
  default_node_pool {
    name            = "system"
    node_count      = var.aks_system_node_count
    vm_size         = var.aks_system_node_size
    vnet_subnet_id  = module.vnet.subnets["aks"].resource_id
    type            = "VirtualMachineScaleSets"
    os_disk_size_gb = 15
  }

  identity {
    type = "SystemAssigned" # It creates a Managed Identity for your AKS cluster to authenticate with other Azure services unlike OIDC which just authenticate the ci/cd to the cluster
  }

  network_profile {
    network_plugin = "azure" # It uses Azure CNI plugin for networking which means PODS can communicate with each other using IP addresses they have got from their subnet pool 

    # On creating a service with type LoadBalancer, AKS uses azure load balancer to assign a public IP address to this service, so you can access your app using the public IP address
    outbound_type = "loadBalancer" # It uses azure standard load balancer Layer 4 to assign a public IP address to the cluster, unlike nginx which is Layer 7

    network_policy = "azure" # Act as a firewall for the cluster
  }

  # Allows Azure AD to trust OIDC tokens from the cluster. 
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  tags = {
    Environment = "Production"
  }
}

# This pool for app pods.
resource "azurerm_kubernetes_cluster_node_pool" "userpool" {
  name                  = "userpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.aks_user_node_size
  node_count            = var.aks_user_node_count
  vnet_subnet_id        = module.vnet.subnets["app"].resource_id # Use your app subnet
  mode                  = "User"
  os_disk_size_gb       = 30
  orchestrator_version  = azurerm_kubernetes_cluster.aks.kubernetes_version

  tags = {
    Environment = "Production"
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true # Assign this role even if the principal isn’t visible in AAD right now.
  # The flag ensures the apply doesn’t fail if the identity isn’t immediately recognized in Azure AD.
}

# avoid Microsoft.Cache/redis through private endpoint or VNet Integration
resource "azurerm_redis_cache" "redis" {
  name                          = "redis-${var.project_name}-${local.suffix}"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  capacity                      = 1
  family                        = "P"
  sku_name                      = var.redis_sku_tier
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  identity {
    type = "SystemAssigned"
  }

  redis_configuration {
    maxmemory_policy = "allkeys-lru" # allkeys means evict the keys whether they got TTL or not, LRU (Least Recently Used) policy to evict the least recently used keys when the memory limit is reached
  }

  tags = {
    Environment = "Production"
  }
}

resource "azurerm_cosmosdb_account" "acc" {
  name                          = var.cosmos_db_account_name
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  offer_type                    = "Standard"
  kind                          = "MongoDB"
  minimal_tls_version           = "Tls12"
  public_network_access_enabled = false
  automatic_failover_enabled    = true # Enable automatic failover to the secondary region

  capabilities {
    name = "mongoEnableDocLevelTTL" # Enable document level TTL (Time to Live) to automatically delete documents after a specified time period
  }

  capabilities {
    name = "EnableMongo" # Enable MongoDB API to use MongoDB drivers and tools to connect to it.
  }

  consistency_policy {                           # the trade-off between read consistency, availability, and latency
    consistency_level       = "BoundedStaleness" # Bounded staleness consistency level
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0 # Primary region
  }

  geo_location {
    location          = var.failover_location
    failover_priority = 1
  }

  # capacity_mode = "Serverless" # Serverless capacity mode allows you to pay only for the resources you use, scaling automatically based on demand

  backup {
    type                = "Periodic"
    interval_in_minutes = 240   # 4 hours
    retention_in_hours  = 48    # 2 days 
    storage_redundancy  = "Geo" # or "Local" or "Zone" geo is the best option for disaster recovery
  }

  tags = {
    Environment = "Production"
  }
}

resource "azurerm_cosmosdb_mongo_database" "mongodb" {
  name                = var.cosmos_db_name
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.acc.name
  autoscale_settings {
    max_throughput = 2000
  }
}

resource "azurerm_cosmosdb_mongo_collection" "collection" {
  name                = var.cosmos_db_name
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.acc.name
  database_name       = azurerm_cosmosdb_mongo_database.mongodb.name

  default_ttl_seconds = "777"       # 777 seconds = 12 minutes 37 seconds, time to live for documents
  shard_key           = "uniqueKey" # distribute data across multiple partitions 
  depends_on          = [azurerm_cosmosdb_mongo_database.mongodb]
}

# Service Endpoints redirect traffic to the public endpoint of the PaaS service (but still over the Azure backbone), whereas Private Link injects the PaaS service into your VNet with a private IP, keeping the traffic fully within your network

module "pe_acr" {
  source                         = "./modules/private_endpoint"
  service_name                   = "acr"
  suffix                         = local.suffix
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnets["private-endpoints"].resource_id
  private_connection_resource_id = azurerm_container_registry.acr.id
  subresource_name               = "registry"
  private_dns_zone_name          = "privatelink.azurecr.io"
  virtual_network_id             = module.vnet.resource_id
}

# private endpoint for redis
module "pe_redis" {
  source                         = "./modules/private_endpoint"
  service_name                   = "redis"
  suffix                         = local.suffix
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnets["private-endpoints"].resource_id
  private_connection_resource_id = azurerm_redis_cache.redis.id
  subresource_name               = "redis"
  private_dns_zone_name          = "privatelink.redis.cache.windows.net"
  virtual_network_id             = module.vnet.resource_id
}

# private endpoint for cosmosdb
module "pe_cosmosdb" {
  source                         = "./modules/private_endpoint"
  service_name                   = "cosmosdb"
  suffix                         = local.suffix
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnets["private-endpoints"].resource_id
  private_connection_resource_id = azurerm_cosmosdb_account.acc.id
  subresource_name               = "cosmosdb"
  private_dns_zone_name          = "privatelink.documents.azure.com"
  virtual_network_id             = module.vnet.resource_id
}

# Steps to securly access Azure Key Vault and grant AKS access to the secrets
# Enable CSI Driver for Azure Key Vault -> 

data "azurerm_client_config" "current" {}
resource "azurerm_key_vault" "kv" {
  name                          = "kv-${var.project_name}-${local.suffix}"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  public_network_access_enabled = false
}

resource "azurerm_key_vault_secret" "cosmos_conn" {
  name         = "cosmos-conn-string"
  value        = azurerm_cosmosdb_account.acc.primary_key
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "redis_conn" {
  name         = "redis-conn-string"
  value        = azurerm_redis_cache.redis.primary_access_key
  key_vault_id = azurerm_key_vault.kv.id
}

# Create a user assigned identity for the pods to access the vault secret
resource "azurerm_user_assigned_identity" "app_identity" {
  name                = "identity-app-${local.suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# Grant the New Identity Access to Key Vault
resource "azurerm_role_assignment" "app_identity_kv_access" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app_identity.principal_id
}

# It links the Azure identity to the Kubernetes SA.
resource "azurerm_federated_identity_credential" "app_fic" {
  name                = "fic-app-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.app_identity.id
  # Service Account my-app-sa issues an OIDC token when the pod starts
  subject = "system:serviceaccount:${local.namespace}:${local.service_account_name}"
}
