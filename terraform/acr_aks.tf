# 1. Create the User-Assigned Identity for the ACR to decrypt the key from valut for CMK encryption
resource "azurerm_user_assigned_identity" "registry_uai" {
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = "registry-uai"
}

# 2. Grant the new identity access to the Key Vault
resource "azurerm_key_vault_access_policy" "registry_identity_access" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.registry_uai.principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey",
  ]
}
resource "azurerm_key_vault_key" "registry_uai_key" {
  name         = "registry-uai-key"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
  # depends_on is not needed here, but we ensure the policy is created first
  depends_on = [azurerm_key_vault_access_policy.registry_identity_access]
}

# 4. Create the ACR and configure encryption
resource "azurerm_container_registry" "acr" {
  name                          = "acr${replace(var.project_name, "-", "")}${local.suffix}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  sku                           = var.acr_sku # Must be "Premium" for CMK
  admin_enabled                 = false
  public_network_access_enabled = false
  zone_redundancy_enabled       = true

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.registry_uai.id]
  }

  encryption {
    key_vault_key_id   = azurerm_key_vault_key.registry_uai_key.versionless_id // versionless_id : ACR will use the latest version of the key which means automatic rotation of the key
    identity_client_id = azurerm_user_assigned_identity.registry_uai.client_id
  }

  tags = {
    Environment = "Production"
  }
}

# create AKS cluster with default node pool

resource "azuread_group" "admin_group" {
  display_name     = "AKS-Cluster-Admins"
  security_enabled = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.project_name}-${local.suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  # aks-mern-1234.westeurope.cloudapp.azure.com
  dns_prefix = "aks-${var.project_name}-${local.suffix}" # It creates a fully qualified domain name for the Kubernetes API Server so that you can manage the cluster
  # to avoid public exposure and make it only accessible within your VNET.
  private_cluster_enabled = true
  # since it is private cluster, we need to create a private DNS zone and link it to the VNET
  private_dns_zone_id                 = azurerm_private_dns_zone.aks_private_dns_zone.id
  private_cluster_public_fqdn_enabled = false
  local_account_disabled              = true
  azure_policy_enabled                = true # enfroce security rules on cluster/pod level like block containers running as root

  # prevent the cluster from being destroyed, extra safety measure
  lifecycle {
    prevent_destroy = true
  }

  # This pool for cluster core pods like kube-system.
  default_node_pool {
    name                         = "system"
    zones                        = ["1", "2"]
    only_critical_addons_enabled = true # will taint default node pool with CriticalAddonsOnly=true:NoSchedule meanning no other pods can be scheduled on it
    # pool rotation: if a propery that forces recreation of the cluster changed, node pods will be moved over to pool_rotation ensuring minimal downtime and delete the old pool 
    temporary_name_for_rotation = "pool_rotation"
    node_count                  = var.aks_system_node_count
    vm_size                     = var.aks_system_node_size
    vnet_subnet_id              = module.vnet.subnets["aks"].resource_id
    type                        = "VirtualMachineScaleSets"
    os_disk_size_gb             = 15
    max_pods                    = 100
  }

  cost_analysis_enabled = true # add Kubernetes Namespace and Deployment details to the Cost Analysis views in the Azure portal.

  identity {
    type = "SystemAssigned" # It creates a Managed Identity for your AKS cluster to authenticate with other Azure services but does not qualify for least-privilege principle
  }
  network_profile {
    # azure native network solution is less suitable for very large or rapidly growing clusters 
    network_plugin      = "azure"         # It uses Azure CNI plugin for networking which means PODS can communicate with each other using IP addresses they have got from their VNet subnet pool 
    network_plugin_mode = "overlay"       # This tell azure to allocate POD IPs from private cidr range
    pod_cidr            = "100.64.0.0/16" # Internal pod CIDR at cluster level so even pods in different node pools still get IPs from the pod cidr
    service_cidr        = "10.0.15.0/24"  # Cluster-internal Service IP range
    dns_service_ip      = "10.0.15.10"    # Must be inside service_cidr
    # It uses azure standard load balancer Layer 4 to assign a public IP address to the cluster making api public endpoint, unlike nginx which is Layer 7
    outbound_type  = "loadBalancer"
    network_policy = "azure" # Act as a firewall for the cluster (native azure approach will be optimized through k8s with network policy on pods)
  }

  # Allows Workload Identity to get OIDC tokens from the cluster. 
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  role_based_access_control_enabled = true
  azure_active_directory_role_based_access_control {
    tenant_id              = data.azurerm_client_config.current.tenant_id
    admin_group_object_ids = [azuread_group.admin_group.object_id]
    azure_rbac_enabled     = true # manage RBAC using Azure AD
  }

  tags = {
    Environment = "Production"
  }
}

# This pool for app pods.
resource "azurerm_kubernetes_cluster_node_pool" "userpool" {
  name                  = "userpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  priority              = "Regular"
  vm_size               = var.aks_user_node_size
  min_count             = var.aks_user_node_min_count
  max_count             = var.aks_user_node_max_count
  auto_scaling_enabled  = true
  zones                 = ["1", "2", "3"]
  vnet_subnet_id        = module.vnet.subnets["app"].resource_id # Use your app subnet for nodes in this pool not pods
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
  # Service Account my-prod-sa issues an OIDC token when the pod starts
  subject = "system:serviceaccount:${local.namespace}:${local.service_account_name}"
}