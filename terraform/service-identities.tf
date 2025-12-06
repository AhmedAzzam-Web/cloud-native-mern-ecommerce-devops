locals {
  services = {
    cart = "cart-sa"
    user = "user-sa"
    product = "product-sa"
  }
}

# Create a user assigned identity (principal ID) for each micro-service to access the vault secret
# Create Managed Identities for ALL microservices
resource "azurerm_user_assigned_identity" "services" {
  for_each            = local.services
  name                = "${each.key}-identity-${local.suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# Grant the New Identity Access to Key Vault
resource "azurerm_role_assignment" "services" {
  for_each            = local.services
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.services[each.key].principal_id
}

# It links the Azure identity to the Kubernetes SA.
resource "azurerm_federated_identity_credential" "services" {
  for_each            = local.services
  name                = "${each.key}-fic-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.services[each.key].id
  # Service Account my-prod-sa issues an OIDC token when the pod starts
  subject = "system:serviceaccount:${local.namespace}:${each.value}"
}
