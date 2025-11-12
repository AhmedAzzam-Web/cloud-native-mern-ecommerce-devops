# Service Endpoints redirect traffic to the public endpoint of the PaaS service (but still over the Azure backbone), whereas Private Link injects the PaaS service into your VNet with a private IP, keeping the traffic fully within your network
### private endpoints with prizate DNS zone (a record) for retrieving private ip addresses without going out to the internet

module "pe_acr" {
  source                         = "./modules/private_endpoint"
  service_name                   = "acr"
  suffix                         = local.suffix
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnets["private-endpoints"].resource_id
  private_connection_resource_id = azurerm_container_registry.acr.id
  subresource_name               = "registry"
  private_dns_zone_name          = "privatelink.azurecr.io"
  virtual_network_id             = module.vnet.resource_id
}

module "pe_aks" {
  source                         = "./modules/private_endpoint"
  service_name                   = "aks"
  suffix                         = local.suffix
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnets["private-endpoints"].resource_id
  private_connection_resource_id = azurerm_kubernetes_cluster.aks.id
  subresource_name               = "aks"
  # search about it
  private_dns_zone_name = "privatelink.${azurerm_resource_group.rg.location}.azmk8s.io"
  virtual_network_id    = module.vnet.resource_id
}

module "pe_redis" {
  source                         = "./modules/private_endpoint"
  service_name                   = "redis"
  suffix                         = local.suffix
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnets["private-endpoints"].resource_id
  private_connection_resource_id = azurerm_redis_cache.redis.id
  subresource_name               = "redis"
  private_dns_zone_name          = "privatelink.redis.cache.windows.net"
  virtual_network_id             = module.vnet.resource_id
}

# private endpoint for cosmosdb
module "pe_cosmosdb" {
  source                         = "./modules/private_endpoint"
  service_name                   = "cosmosdb"
  suffix                         = local.suffix
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnets["private-endpoints"].resource_id
  private_connection_resource_id = azurerm_cosmosdb_account.acc.id
  subresource_name               = "cosmosdb"
  private_dns_zone_name          = "privatelink.documents.azure.com"
  virtual_network_id             = module.vnet.resource_id
}

module "pe_kv" {
  source                         = "./modules/private_endpoint"
  service_name                   = "key_vault"
  suffix                         = local.suffix
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnets["private-endpoints"].resource_id
  private_connection_resource_id = azurerm_key_vault.kv.id
  subresource_name               = "key_vault"
  private_dns_zone_name          = "privatelink.vaultcore.azure.net"
  virtual_network_id             = module.vnet.resource_id
}