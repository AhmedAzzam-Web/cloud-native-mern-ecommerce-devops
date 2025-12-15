# Core azure resources: RG, ACR, AKS, Module(VNET, Subnet), Redis_cache, Cosmos_DB_for_MongoDB

locals {
  suffix               = random_string.random.result
  namespace            = "prod"
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
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  version             = "0.10.0"
  name                = "vnet-${var.project_name}-${local.suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  # Private Endpoints, securely access a public Azure PaaS service (like ACR) from your private network through azure private link and private DNS
  subnets = {
    "aks" = {
      name             = "subnet1 for aks"
      address_prefixes = ["10.0.0.0/20"]
    }
    # This app subnet consumes private_endpoint_network_policies so we disable NSGs and UDRs to avoid conflicts
    "app" = {
      name                              = "subnet2 for apps"
      address_prefixes                  = ["10.0.1.0/24"]
      private_endpoint_network_policies = "Disabled" # to prevent policies from affecting outbound to Private Endpoints
    }
    "private-endpoints" = {
      name             = "subnet3 for private-endpoints services"
      address_prefixes = ["10.0.2.0/24"]
    }
    # azure bastion to access aks cluster via private endpoint
    "bastion" = {
      name             = "AzureBastionSubnet"
      address_prefixes = ["10.0.3.0/24"]
    }
    "alb_subnet" = {
      name                                  = "alb_subnet"
      address_prefixes                      = ["10.0.4.0/24"]
      # Delegation means that subnet is delegated to the azure service to manage the subnet
      # AGFC is managed by microsoft, but it has to join the private network so delegation is required
      delegation = {
        name = "delegation"
        service_delegation = {
          name    = "Microsoft.ServiceNetworking/trafficControllers"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }
    }
  }
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
  purge_protection_enabled      = true # prevent the secret from being deleted permenantly even by admins, for compliance purposes
  soft_delete_retention_days    = 90   # retain the deleted key vault for 90 days
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
