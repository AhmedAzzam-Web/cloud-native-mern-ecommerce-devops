# Azure Bastion to access the AKS cluster via private endpoint

resource "azurerm_public_ip" "bastion_ip" {
  name                = "bastion-pip-${local.suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2"]
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-${local.suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  ip_configuration {
    name                 = "bastion_ip_config"
    subnet_id            = module.vnet.subnets["bastion"].resource_id
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }

  copy_paste_enabled = true
  file_copy_enabled  = true
}
