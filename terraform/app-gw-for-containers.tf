# https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller?tabs=install-helm-windows

# 1. User Assigned Identity for the ALB Controller
# The naming of azure-alb-identity is a must for the AGFC controller to work
resource "azurerm_user_assigned_identity" "azure-alb-identity" {
  name                = "alb-controller-identity-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# 2. Federated Credential (Workload Identity)
resource "azurerm_federated_identity_credential" "azure-alb-identity" {
  name                = "alb-controller-fic-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.azure-alb-identity.id
  # The naming of subject is a must for the AGFC controller to work. The official ALB Helm chart defaults the Service Account name to alb-controller-sa
  subject = "system:serviceaccount:azure-alb-system:alb-controller-sa"
}

# This allows the controller to Create/Update the AGFC resource in the Resource Group
resource "azurerm_role_assignment" "azure-alb-contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "AppGw for Containers Configuration Manager"
  principal_id         = azurerm_user_assigned_identity.azure-alb-identity.principal_id
}

# This allows the controller to inject the gateway into the subnet
resource "azurerm_role_assignment" "azure-alb-subnet-join" {
  scope                = module.vnet.subnets["alb_subnet"].resource_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.azure-alb-identity.principal_id
}
