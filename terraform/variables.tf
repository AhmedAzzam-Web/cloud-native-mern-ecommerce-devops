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
  default     = 2
}
variable "aks_user_node_min_count" {
  type        = number
  description = "The initial quantity of nodes for the node pool."
  default     = 3
}
variable "aks_user_node_max_count" {
  type        = number
  description = "The initial quantity of nodes for the node pool."
  default     = 6
}

variable "aks_system_node_size" {
  description = "Node size the smallest for cost"
  type        = string
  # ~1 vCPU/2GB; economical for small workloads
  default = "Standard_B1s"
}

variable "aks_user_node_size" {
  description = "Node size the smallest for cost"
  type        = string
  # 2vCPU/4GB; after OS and kubelet overhead, get 1.46 vCPUs, 3.71 GiB RAM; min 3 nodes: 5.18 vCPUs, 11.13 GiB RAM
  # total memory needed for pods: 6.75 GiB , total cpu needed for pods: 3.6 vCPUs , SLA is good
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
