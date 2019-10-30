provider "azurerm" {
  profile    = "default"
  region     = "us-east-1"
}

resource "azurerm_resource_group" "rg_hub_network" {
  name     = "bdc_canada_central_hub_network"
  location = "${var.location}"
}
resource "azurerm_network_security_group" "nsg_coreservices" {
  name                = "core_services_central"
  location            = "${azurerm_resource_group.rg_hub_network.location}"
  resource_group_name = "${azurerm_resource_group.rg_hub_network.name}"
}
resource "azurerm_network_security_group" "nsg_management" {
  name                = "management_central"
  location            = "${azurerm_resource_group.rg_hub_network.location}"
  resource_group_name = "${azurerm_resource_group.rg_hub_network.name}"
}
resource "azurerm_virtual_network" "vnet_core" {
  name                = "bdc_canada_central_core_vnet"
  location            = "${azurerm_resource_group.rg_hub_network.location}"
  resource_group_name = "${azurerm_resource_group.rg_hub_network.name}"
  address_space       = ["10.255.120.0/21"]
  dns_servers         = ["10.253.212.10", "10.253.212.11"]

  subnet {
    name           = "GatewaySubnet"
    address_prefix = "10.255.124.0/29"
  }
  subnet {
    name           = "connectivity_external_central"
    address_prefix = "10.255.127.0/24"
    route_table_id = "${azurerm_route_table.routetable_1.id}"
  }
  subnet {
    name           = "connectivity_internal_central"
    address_prefix = "10.255.125.0/24"
    route_table_id = "${azurerm_route_table.routetable_2.id}"
  }
  subnet {
    name           = "core_services_central"
    address_prefix = "10.255.121.0/24"
    security_group = "${azurerm_network_security_group.nsg_coreservices.id}"
    route_table_id = "${azurerm_route_table.routetable_2.id}"
  }
  subnet {
    name           = "management_central"
    address_prefix = "10.255.120.0/24"
    security_group = "${azurerm_network_security_group.nsg_management.id}"
    route_table_id = "${azurerm_route_table.routetable_2.id}"
  }
  subnet {
    name           = "hubdmz_in_central"
    address_prefix = "10.255.122.0/27"
  }
  subnet {
    name           = "hubdmz_out_central"
    address_prefix = "10.255.122.32/27"
    route_table_id = "${azurerm_route_table.routetable_2.id}"
  }
}

resource "azurerm_network_interface" "nic_comm_internal" {
  name                = "Comm-Internal"
  location            = "${azurerm_resource_group.rg_hub_network.location}"
  resource_group_name = "${azurerm_resource_group.rg_hub_network.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.connectivity_internal_central.id}"
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_network_interface" "nic_internal" {
  name                = "Internal"
  location            = "${azurerm_resource_group.rg_hub_network.location}"
  resource_group_name = "${azurerm_resource_group.rg_hub_network.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.connectivity_internal_central.id}"
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_resource_group" "rg_hub_network_connectivity" {
  name     = "bdc_canada_central_hub_network_connectivity"
  location = "${var.location}"
}

resource "azurerm_route_table" "routetable_1" {
  name                          = "subnet1-CSR-RouteTable"
  location                      = "${azurerm_resource_group.rg_hub_network_connectivity.location}"
  resource_group_name           = "${azurerm_resource_group.rg_hub_network_connectivity.name}"
  disable_bgp_route_propagation = false
}
resource "azurerm_subnet_route_table_association" "rt11" {
  subnet_id      = "${azurerm_subnet.connectivity_external_central.id}"
  route_table_id = "${azurerm_route_table.routetable_1.id}"
}
resource "azurerm_route_table" "routetable_2" {
  name                          = "subnet2-CSR-RouteTable"
  location                      = "${azurerm_resource_group.rg_hub_network_connectivity.location}"
  resource_group_name           = "${azurerm_resource_group.rg_hub_network_connectivity.name}"
  disable_bgp_route_propagation = false

  route {
    name           = "bdc_ho_route"
    address_prefix = "10.252.0.0/16"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.255.125.6" 
  }
  route {
    name           = "bdc_rldc_route"
    address_prefix = "10.253.0.0/16"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.255.125.6"
  }
  route {
    name           = "bdc_sldc_route"
    address_prefix = "10.254.0.0/16"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.255.125.6"
  }
  route {
    name           = "default_via_chekpoint_cluster_in_azure"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.255.122.38"
  }
}
resource "azurerm_subnet_route_table_association" "test" {
  subnet_id      = "${azurerm_subnet.test.id}"
  route_table_id = "${azurerm_route_table.test.id}"
}





resource "azurerm_resource_group" "" {
  name     = "bdc_canada_central_hub_network_firewall"
  location = "${var.location}"
}

resource "azurerm_resource_group" "bdc_canada_central_hub_network_firewall_outbound" {
  name     = "bdc_canada_central_hub_network_firewall_outbound"
  location = "${var.location}"
}
resource "azurerm_resource_group" "NetworkWatcheRG" {
  name     = "NetworkWatcheRG"
  location = "${var.location}"
}


