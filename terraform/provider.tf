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
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.1.1"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstate_prod_infrastructure"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate" # you decide this value not default to a name haha, save the state in this file
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_secrets_on_destroy = true // purge means delete the secret from the key vault permenantly
      recover_soft_deleted_secrets          = true // when we delete a secret, it just gets soft deleted and we can recover it later
    }
  }
}

provider "helm" {
  # ADD THE EQUALS SIGN HERE 
  kubernetes = {
    host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  }
}