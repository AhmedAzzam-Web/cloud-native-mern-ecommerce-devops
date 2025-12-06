# Service Endpoints redirect traffic to the public endpoint of the PaaS service (but still over the Azure backbone), whereas Private Link injects the PaaS service into your VNet with a private IP, keeping the traffic fully within your network
### private endpoints with prizate DNS zone (a record) for retrieving private ip addresses without going out to the internet

locals {
  private_endpoints = {
    acr = {
      service_name = "acr"
      subresource_name = "registry"
      private_connection_resource_id = azurerm_container_registry.acr.id
      private_dns_zone_name = "privatelink.azurecr.io"
    }
    aks = {
      service_name = "aks"
      subresource_name = "management"
      private_connection_resource_id = azurerm_kubernetes_cluster.aks.id
      private_dns_zone_name = "privatelink.${azurerm_resource_group.rg.location}.azmk8s.io"
    }
    redis = {
      service_name = "redis"
      subresource_name = "redis"
      private_connection_resource_id = azurerm_redis_cache.redis.id
      private_dns_zone_name = "privatelink.redis.cache.windows.net"
    }
    cosmosdb = {
      service_name = "cosmosdb"
      subresource_name = "cosmosdb"
      private_connection_resource_id = azurerm_cosmosdb_account.acc.id
      private_dns_zone_name = "privatelink.documents.azure.com"
    }
    key_vault = {
      service_name = "key_vault"
      subresource_name = "vault"
      private_connection_resource_id = azurerm_key_vault.kv.id
      private_dns_zone_name = "privatelink.vaultcore.azure.net"
    }
  }
}

module "private_endpoints" {
  for_each = local.private_endpoints
  source = "./modules/private_endpoint"
  service_name = each.value.service_name
  suffix = local.suffix
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id = module.vnet.subnets["private-endpoints"].resource_id
  private_connection_resource_id = each.value.private_connection_resource_id
  subresource_name = each.value.subresource_name
  private_dns_zone_name = each.value.private_dns_zone_name
  virtual_network_id = module.vnet.resource_id
}