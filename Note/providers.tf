terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    # CRITICAL FIX: Setting this to 'false' allows Terraform to successfully 
    # destroy the old Resource Group (urban-rg), even though it still contained 
    # the old Data Factory resource in Azure's state. Azure will perform the 
    # cascade delete of nested resources.
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "random" {}
