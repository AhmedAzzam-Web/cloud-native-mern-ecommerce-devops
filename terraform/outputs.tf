output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Resource group name"
}

# --- Core AKS, ACR and Connectivity Outputs ---
output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  value       = azurerm_container_registry.acr.login_server
  description = "ACR registry hostname"
  sensitive   = true
}

output "aks_cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "AKS cluster name"
}
output "aks_kube_config_raw" {
  description = "Raw Kubernetes config for connecting to the private AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true # Mark as sensitive because it contains credentials
}

output "aks_cluster_id" {
  description = "The Azure Resource ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_oidc_issuer_url" {
  description = "The OIDC issuer URL for Workload Identity. Used in Kubernetes Service Account configuration."
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

# Granting permissions to other Azure resources troubleshooting 
output "aks_system_assigned_identity_principal_id" {
  description = "The Principal ID of the AKS cluster's system-assigned managed identity. Useful for granting permissions to other Azure resources."
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# Connect to the AKS cluster via Bastion name, but bastion_ip is for bastion's dns resolution troubleshooting
output "bastion_public_ip_address" {
  description = "The Public IP address of the Azure Bastion Host. Use this to connect via web browser to your internal VMs/nodes."
  value       = azurerm_public_ip.bastion_ip.ip_address
}

output "bastion_host_name" {
  description = "The name of the Azure Bastion Host."
  value       = azurerm_bastion_host.bastion.name
}


# --- PaaS Service Connection Details ---

output "cosmosdb_account_name" {
  description = "The name of the Azure Cosmos DB account."
  value       = azurerm_cosmosdb_account.acc.name
}


output "redis_host_name" {
  description = "The hostname of the Azure Cache for Redis instance."
  value       = azurerm_redis_cache.redis.hostname
}

# key_vault_uri: to check secret provider class not connected to the key vault issue
output "key_vault_uri" {
  description = "The URI of the Azure Key Vault."
  value       = azurerm_key_vault.kv.vault_uri
}

# --- Networking Details ---

output "vnet_name" {
  description = "The name of the Virtual Network."
  value       = module.vnet.name
}

output "vnet_id" {
  description = "The Resource ID of the Virtual Network."
  value       = module.vnet.resource_id
}

output "aks_subnet_id" {
  description = "The Resource ID of the subnet used for AKS nodes."
  value       = module.vnet.subnets["aks"].resource_id
}

output "app_subnet_id" {
  description = "The Resource ID of the subnet used for application node pool."
  value       = module.vnet.subnets["app"].resource_id
}

output "private_endpoints_subnet_id" {
  description = "The Resource ID of the subnet dedicated for private endpoints."
  value       = module.vnet.subnets["private-endpoints"].resource_id
}

output "bastion_subnet_id" {
  description = "The Resource ID of the AzureBastionSubnet."
  value       = module.vnet.subnets["bastion"].resource_id
}

# --- Identity Outputs ---

output "cart_identity_client_id" {
  description = "The client ID of the User-Assigned Identity for cart pods (used for Workload Identity)."
  value       = azurerm_user_assigned_identity.services["cart"].client_id
}

output "user_identity_client_id" {
  description = "The client ID of the User-Assigned Identity for user pods (used for Workload Identity)."
  value       = azurerm_user_assigned_identity.services["user"].client_id
}

output "product_identity_client_id" {
  description = "The client ID of the User-Assigned Identity for product pods (used for Workload Identity)."
  value       = azurerm_user_assigned_identity.services["product"].client_id
}

output "registry_uai_client_id" {
  description = "The Client ID of the User-Assigned Identity for ACR (used for CMK encryption)."
  value       = azurerm_user_assigned_identity.registry_uai.client_id
}

output "registry_uai_principal_id" {
  description = "The Principal ID of the User-Assigned Identity for ACR (used for CMK encryption)."
  value       = azurerm_user_assigned_identity.registry_uai.principal_id
}

# New Developer Can't Access the Cluster Troubleshooting
output "aks_admin_group_object_id" {
  description = "The Object ID of the Azure AD group configured for AKS administrative access."
  value       = azuread_group.admin_group.object_id
}

# Subnet ID for AGFC controller to be used in the gateway.yaml
output "alb_subnet_id" {
  description = "The Resource ID of the subnet used for Application Gateway for Containers."
  value       = module.vnet.subnets["alb_subnet"].resource_id
}
