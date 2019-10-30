output "azure_resource_group_name" {
  value = "${azurerm_resource_group.test.name}"
}

output "azure_resource_group_location" {
  value = "${azurerm_resource_group.test.location}"
}

output "azurerm_network_security_group" {
  value = "${azurerm_network_security_group.test.name}"
}

output "azurerm_subnet_internal_id" {
  value = "${azurerm_subnet.test.id}"
}

output "postfix" {
  value = "${var.postfix}"
}

