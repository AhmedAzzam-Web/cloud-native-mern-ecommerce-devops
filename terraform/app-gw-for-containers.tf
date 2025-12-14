# https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller?tabs=install-helm-windows

# 1. User Assigned Identity for the ALB Controller
resource "azurerm_user_assigned_identity" "alb_identity" {
  name                = "alb-controller-identity-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# 2. Federated Credential (Workload Identity)
resource "azurerm_federated_identity_credential" "alb_identity_fic" {
  name                = "alb-controller-fic-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.alb_identity.id
  subject             = "system:serviceaccount:azure-alb-system:alb-controller-sa"
}

# 3. Role Assignment: AppGw for Containers Configuration Manager
# This allows the controller to Create/Update the AGFC resource in the Resource Group
resource "azurerm_role_assignment" "alb_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "AppGw for Containers Configuration Manager"
  principal_id         = azurerm_user_assigned_identity.alb_identity.principal_id
}

# 4. Role Assignment: Network Contributor on the Subnet
# This allows the controller to inject the gateway into the subnet
resource "azurerm_role_assignment" "alb_subnet_join" {
  scope                = azurerm_subnet.alb_subnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.alb_identity.principal_id
}

resource "helm_release" "alb_controller" {
  name             = "alb-controller"
  repository       = "oci://mcr.microsoft.com/application-lb/charts"
  chart            = "alb-controller"
  version          = "1.3.7"
  namespace        = "azure-alb-system"
  create_namespace = true

  # Pass the Client ID of the identity we created above
  set = [
    {
      name  = "albController.podIdentity.clientID"
      value = azurerm_user_assigned_identity.alb_identity.client_id
    },
    {
      name  = "albController.podIdentity.enabled"
      value = "true"
    }
  ]
  depends_on = [
    azurerm_federated_identity_credential.alb_identity_fic
  ]
}
