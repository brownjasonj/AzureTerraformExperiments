output "resource-group-name" {
    description = "String name of the resource group created."
    value = azurerm_resource_group.default.name
}