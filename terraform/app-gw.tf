resource "azurerm_public_ip" "app-gw-pip" {
  name                = "app-gw-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2"] # for high availability

  tags = {
    Environment = "Production"
  }
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${module.vnet.name}-beap"
  frontend_port_name             = "${module.vnet.name}-feport"
  frontend_ip_configuration_name = "${module.vnet.name}-feip"
  http_setting_name              = "${module.vnet.name}-be-htst"
  listener_name                  = "${module.vnet.name}-httplstn"
  request_routing_rule_name      = "${module.vnet.name}-rqrt"
  redirect_configuration_name    = "${module.vnet.name}-rdrcfg"
}

resource "azurerm_application_gateway" "app-gw" {
  name                = "app-gw-${var.project_name}-${local.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  # I don't have a domain name to get Let's Encrypt SSL certificate yet, so I'm using Standard_v2
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  autoscale_configuration {
    min_capacity = 2
    max_capacity = 10
  }

  gateway_ip_configuration {
    name      = "app-gw-ip-configuration"
    subnet_id = module.vnet.subnets["app-gw"].id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.app-gw-pip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    # AGIC connectes to backend services via HTTP (Kubernetes service is usually HTTP internally)
    protocol        = "Http"
    request_timeout = 20
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}
