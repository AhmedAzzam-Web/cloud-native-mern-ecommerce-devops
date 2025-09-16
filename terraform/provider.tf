terraform {
  required_version = ">=1.9.1"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.42.0" # Specify the desired version range
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_secrets_on_destroy = true
      recover_soft_deleted_secrets          = true
    }
  }
}

