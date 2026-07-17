terraform {
  required_version = ">= 1.10.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # In a real deployment, state would be stored remotely:
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "sthmctsterraformstate"
  #   container_name       = "tfstate"
  #   key                  = "case-tracker/production.tfstate"
  # }
}

provider "azurerm" {
  features {}
}