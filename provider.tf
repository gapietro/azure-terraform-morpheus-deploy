# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id             = ""
  client_id                   = ""
  client_secret               = var.client_secret
  tenant_id                   = ""
}

