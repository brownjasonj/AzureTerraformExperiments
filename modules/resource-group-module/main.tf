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

# Create Resource Group 
resource "azurerm_resource_group" "default" {
  location = var.region
  name = format("rg-%s-%s-%s", var.name, var.region, uuid())
}
