# Terraform Settings Block
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">=3.0"
    }    
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

locals {
  name = "azuretf"
  location = "northeurope"
}


module "storage-account-module" {
  source = "../../modules/storage-account-module"
  name = local.name
  location = local.location
}