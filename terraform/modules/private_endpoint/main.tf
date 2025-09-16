resource "azurerm_private_endpoint" "pe" {
  name                = "pe-${var.service_name}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "psc-${var.service_name}-${var.suffix}"
    private_connection_resource_id = var.private_connection_resource_id
    subresource_names              = [var.subresource_name]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-${var.service_name}-${var.suffix}"
    private_dns_zone_ids = [azurerm_private_dns_zone.pdnsz.id]
  }
}

resource "azurerm_private_dns_zone" "pdnsz" {
  name                = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "link" {
  name                  = "dns-link-${var.service_name}-${var.suffix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.pdnsz.name
  virtual_network_id    = var.virtual_network_id
}