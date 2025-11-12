
resource "azurerm_cosmosdb_account" "acc" {
  name                          = var.cosmos_db_account_name
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  offer_type                    = "Standard"
  kind                          = "MongoDB"
  minimal_tls_version           = "Tls12"
  public_network_access_enabled = false
  automatic_failover_enabled    = true # Enable automatic failover to the secondary region

  capabilities {
    name = "mongoEnableDocLevelTTL" # Enable document level TTL (Time to Live) to automatically delete documents after a specified time period
  }

  capabilities {
    name = "EnableMongo" # Enable MongoDB API to use MongoDB drivers and tools to connect to it.
  }

  consistency_policy {                           # the trade-off between read consistency, availability, and latency
    consistency_level       = "BoundedStaleness" # Bounded staleness consistency level
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0 # Primary region
  }

  geo_location {
    location          = var.failover_location
    failover_priority = 1
  }

  # capacity_mode = "Serverless" # Serverless capacity mode allows you to pay only for the resources you use, scaling automatically based on demand

  backup {
    type                = "Periodic"
    interval_in_minutes = 240   # 4 hours
    retention_in_hours  = 48    # 2 days 
    storage_redundancy  = "Geo" # or "Local" or "Zone" geo is the best option for disaster recovery
  }

  tags = {
    Environment = "Production"
  }
}

resource "azurerm_cosmosdb_mongo_database" "mongodb" {
  name                = var.cosmos_db_name
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.acc.name
  autoscale_settings {
    max_throughput = 2000
  }
}

resource "azurerm_cosmosdb_mongo_collection" "collection" {
  name                = var.cosmos_db_name
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.acc.name
  database_name       = azurerm_cosmosdb_mongo_database.mongodb.name

  default_ttl_seconds = "777"       # 777 seconds = 12 minutes 37 seconds, time to live for documents
  shard_key           = "uniqueKey" # distribute data across multiple partitions 
  depends_on          = [azurerm_cosmosdb_mongo_database.mongodb]
}