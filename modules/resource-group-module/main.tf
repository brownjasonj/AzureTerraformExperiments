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

resource "random_uuid" "rg_name" {}

# Create Resource Group 
resource "azurerm_resource_group" "default" {
  location = var.location
  name = "${random_uuid.rg_name.result}-${var.name}-${var.location}"
}

