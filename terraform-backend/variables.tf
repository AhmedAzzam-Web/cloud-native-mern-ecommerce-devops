variable "resource_group_name" {
  default  = "tfstate-ecommerce-prod-rg"
  description = "Name of the resource group for the backend."
  type        = string
}

variable "location" {
  default = "uaenorth"
  description = "Azure region for the backend."
  type        = string
}
