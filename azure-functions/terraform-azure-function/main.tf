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

# Create a resource group within which we place the Azure Function
resource "azurerm_resource_group" "resource_group" {
  name = "${var.project}-${var.environment}-resource-group"
  location = var.location
}

# Create storage account for the Azure Function.  Note: Storage account name cannot include hyphens.
/* resource "azurerm_storage_account" "storage_account" {
  name = "${var.project}${var.environment}storage"
  resource_group_name = azurerm_resource_group.resource_group.name
  location = var.location
  account_tier = "Standard"
  account_replication_type = "LRS"
}
*/

resource "azurerm_virtual_network" "storage_account" {
  name                = format("%s-%s-virtual-network", var.project, var.environment)
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet" "storage_account" {
  name                 = format("%s-%s-subnet", var.project, var.environment)
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.storage_account.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage"]
}

resource "azurerm_storage_account" "storage_account" {
  name                = "${var.project}${var.environment}sa"
  resource_group_name = azurerm_resource_group.resource_group.name

  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny"
    ip_rules                   = ["100.0.0.1"]
    virtual_network_subnet_ids = [azurerm_subnet.storage_account.id]
  }

  tags = {
    environment = "staging"
  }
}

# Create application insights for the Azure Function.  Insights is a component to collect metrics and logs from the function
resource "azurerm_application_insights" "application_insights" {
  name                = "${var.project}-${var.environment}-application-insights"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  application_type    = "Node.JS"
}

/*
 Create Function Service Plan

 There are 3 plans available:

    - Consumption Plan. Serverless, scales automatically with the number of events. No events => zero instances (you pay nothing).
    - Premium Plan. You reserve a number of always-ready instances which run no matter if there are events or not. As load grows, new instances are added automatically.
    - Dedicated (App Service) Plan. FAs will run on VMs managed by you. Doesn't scale automatically based on events.

*/
resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "${var.project}-${var.environment}-app-service-plan"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  kind                = "FunctionApp"
  reserved = true # this has to be set to true for Linux. Not related to the Premium Plan
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

/*
    The final resource we need to create is the function app itself. It references resources created earlier: 
    
        App Service Plan
        Application Insights instance
        Storage account. 

    Version is set to 3, which is the latest version of Azure Functions at the moment.

    app_settings is a key-value block with configuration options for all of the functions in the Function App. 
    If you need to pass an environment variable to your code, add it here.

    If you publish code with other tools (e.g. Azure Functions Core Tools, or VS Code, or use ZIP deploy directly), 
    they may change the value of WEBSITE_RUN_FROM_PACKAGE. To prevent Terraform from reporting about configuration
    drift in these cases, we set the app setting to an empty value and ignore changes in the lifecycle block. 
    Note: alternatively you can deploy the function code with Terraform too - there won't be this issue then.

    For CORS configuration, check the cors parameter in the resource documentation.
*/
resource "azurerm_function_app" "function_app" {
  name                       = format("%s-function-app",uuid())
  resource_group_name        = azurerm_resource_group.resource_group.name
  location                   = var.location
  app_service_plan_id        = azurerm_app_service_plan.app_service_plan.id
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "",
    "FUNCTIONS_WORKER_RUNTIME" = "node",
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.application_insights.instrumentation_key,
  }
  os_type = "linux"
  site_config {
    linux_fx_version          = "node|14"
    use_32_bit_worker_process = false
  }
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  version                    = "~3"

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

