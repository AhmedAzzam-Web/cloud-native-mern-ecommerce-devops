output "acr_login_server" {
  description = "The login server for the Azure Container Registry <acr_name>.azurecr.io"
  value       = azurerm_container_registry.acr.login_server
}

output "aks_cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
}

output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
}

# needed by service account file in k8s/service_account.yaml file
output "app_identity_client_id" {
  value = azurerm_user_assigned_identity.app_identity.client_id
}