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

module "resource-group-module" {
  source = "../../modules/resource-group-module"
  name = "test"
  region = "westus"
}