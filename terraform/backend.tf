resource "azurerm_resource_group" "tfstate" {
  name     = "tfstate"
  location = "uaenorth"
}

resource "azurerm_storage_account" "tfstate" {
  name                          = "tfstate_prod_infrastructure"
  resource_group_name           = azurerm_resource_group.tfstate.name
  location                      = azurerm_resource_group.tfstate.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  public_network_access_enabled = false
  min_tls_version               = "TLS1_2"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}
