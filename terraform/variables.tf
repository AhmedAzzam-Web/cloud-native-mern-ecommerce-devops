# Premium SKU allows for private endpoints so that we can have no external access

variable "resource_group_name" {
  type    = string
  default = "ecommerce-mern-rg"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "uaenorth"
}

variable "project_name" {
  description = "Project name used to name all resources"
  type        = string
  default     = "ecommerce-mern"
}

variable "acr_sku" {
  description = "sku (stock keeping unit for pricing plan): Basic, Standard, Premium"
  type        = string
  default     = "Premium"
}

variable "aks_system_node_count" {
  type        = number
  description = "The initial quantity of nodes for the node pool."
  default     = 1
}

variable "aks_user_node_count" {
  type        = number
  description = "The initial quantity of nodes for the node pool."
  default     = 2
}

variable "aks_system_node_size" {
  description = "Node size the smallest for cost"
  type        = string
  # Standard_DS2_v2 ~1 vCPU/2GB; economical for small workloads
  default = "Standard_B1s"
}

variable "aks_user_node_size" {
  description = "Node size the smallest for cost"
  type        = string
  # Standard_B2s ~2 vCPU/4GB; economical for small workloads
  default = "Standard_B2s"
}

variable "redis_sku_tier" {
  description = "The SKU pricing tier for the Redis Cache."
  type        = string
  default     = "Premium"
}

# Cosmos DB variables
variable "cosmos_db_account_name" {
  default = "cosmosdb-acc"
  type    = string
}

variable "cosmos_db_name" {
  default = "cosmos-mongodb-database"
  type    = string
}

variable "cosmos_db_collection_name" {
  default = "cosmos-mongodb-collection"
  type    = string
}

variable "failover_location" {
  default = "polandcentral"
  type    = string
}
