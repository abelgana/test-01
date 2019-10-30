# Configure the Azure Provider
provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.28.0"
}

# Create a resource group
resource "azurerm_resource_group" "test" {
  name     = "RG-${var.postfix}"
  location = "${var.location}"
  tags     = "${var.tags}"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "test" {
  name                = "VNET-${var.postfix}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  location            = "${azurerm_resource_group.test.location}"
  address_space       = ["10.7.11.0/24"]
  tags                = "${var.tags}"
}

resource "azurerm_subnet" "test" {
  name                 = "SN-${var.postfix}"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "10.7.11.0/25"

  #  network_security_group_id = "${azurerm_network_security_group.test.id}"
}

resource "azurerm_subnet_network_security_group_association" "test" {
  subnet_id                 = "${azurerm_subnet.test.id}"
  network_security_group_id = "${azurerm_network_security_group.test.id}"
}

# resource "azurerm_subnet" "gateway" {
#   name                      = "${var.gwsubname}"
#   resource_group_name       = "${azurerm_resource_group.test.name}"
#   virtual_network_name      = "${azurerm_virtual_network.test.name}"
#   address_prefix            = "10.7.11.240/28"
#   network_security_group_id = "${azurerm_network_security_group.test.id}"
# }
#
# resource "azurerm_public_ip" "gateway" {
#   name                = "${var.gwsubname}"
#   location            = "${var.location}"
#   resource_group_name = "${azurerm_resource_group.test.name}"
#   allocation_method   = "Dynamic"
#   tags                = "${var.tags}"
# }
#
# resource "azurerm_virtual_network_gateway" "gateway" {
#   name                = "VNG-${var.postfix}"
#   location            = "${var.location}"
#   resource_group_name = "${azurerm_resource_group.test.name}"
#   type                = "vpn"
#   vpn_type            = "RouteBased"
#   sku                 = "Basic"
#
#   ip_configuration {
#     name                 = "${azurerm_subnet.gateway.name}"
#     subnet_id            = "${azurerm_subnet.gateway.id}"
#     public_ip_address_id = "${azurerm_public_ip.gateway.id}"
#   }
#
#   tags = "${var.tags}"
# }

resource "azurerm_network_security_group" "test" {
  name                = "NSG-${var.postfix}"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  tags                = "${var.tags}"
}

resource "azurerm_network_security_rule" "rule1" {
  name                        = "AllowAllSameSubnet"
  description                 = "Allow all traffic same subnet"
  access                      = "Allow"
  protocol                    = "*"
  direction                   = "Inbound"
  priority                    = 100
  destination_port_range      = "*"
  source_address_prefix       = "${azurerm_subnet.test.address_prefix}"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.test.name}"
  network_security_group_name = "${azurerm_network_security_group.test.name}"
}

resource "azurerm_network_security_rule" "rule2" {
  name                        = "DenyAll"
  description                 = "Default Deny all traffic"
  access                      = "Deny"
  protocol                    = "*"
  direction                   = "Inbound"
  priority                    = 4096
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  resource_group_name         = "${azurerm_resource_group.test.name}"
  network_security_group_name = "${azurerm_network_security_group.test.name}"
}

resource "azurerm_network_security_rule" "rule3" {
  name                        = "AllowLMCollectorAllSubnet"
  description                 = "Allow LM Collector"
  access                      = "Allow"
  protocol                    = "*"
  direction                   = "Inbound"
  priority                    = 101
  source_address_prefixes     = ["10.7.1.31", "10.7.1.32"]
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "135"
  resource_group_name         = "${azurerm_resource_group.test.name}"
  network_security_group_name = "${azurerm_network_security_group.test.name}"
}

resource "azurerm_recovery_services_vault" "test" {
  name                = "C-RSV-${var.postfix}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  location            = "${azurerm_resource_group.test.location}"
  sku                 = "Standard"
  tags                = "${var.tags}"
}

resource "azurerm_recovery_services_protection_policy_vm" "test" {
  name                = "NBVMDaily"
  resource_group_name = "${azurerm_resource_group.test.name}"
  recovery_vault_name = "${azurerm_recovery_services_vault.test.name}"

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 14
  }

  tags = "${var.tags}"
}

resource "azurerm_storage_account" "logs" {
  name                     = "${var.loggingstorageaccount}"
  location                 = "${azurerm_resource_group.test.location}"
  resource_group_name      = "${azurerm_resource_group.test.name}"
  account_kind             = "Storage"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = "${var.tags}"
}

resource "azurerm_storage_account" "sql_backups" {
  name                     = "${var.sqlbckstorageaccount}"
  location                 = "${azurerm_resource_group.test.location}"
  resource_group_name      = "${azurerm_resource_group.test.name}"
  account_kind             = "Storage"
  account_tier             = "Standard"
  account_replication_type = "GRS"
  tags                     = "${var.tags}"
}

