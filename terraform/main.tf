terraform {
  backend "azurerm" {
    resource_group_name  = "KobiAssignment"
    storage_account_name = "sadevweu01"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x.
  # If you're using version 1.x, the "features" block is not allowed.
  version = "~>3.74.0"
  features {}
}

data "azurerm_client_config" "current" {}

# Data RG
data "azurerm_resource_group" "rg" {
  name = "KobiAssignment"
}

# Create Hub Virtual Network
resource "azurerm_virtual_network" "hub_vnet" {
  name                = "hub-vnet"
  address_space       = ["192.168.0.0/16"]
  location            = "westeurope"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Create Hub Subnet
resource "azurerm_subnet" "hub_subnet" {
  name                 = "hub-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["192.168.1.0/24"]
}

# Create App GW Subnet - Front
resource "azurerm_subnet" "front_subnet" {
  name                 = "front-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["192.168.3.0/24"]
}

# Create App GW Subnet - Back
resource "azurerm_subnet" "back_subnet" {
  name                 = "back-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["192.168.4.0/24"]
}

# Create AKS
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "kobi-aks"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "kobik8scluster"

  default_node_pool {
    name       = "default"
    node_count = "2"
    vm_size    = "standard_d2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Create PIP
resource "azurerm_public_ip" "gw_pip" {
  name                = "kobi-gw-pip"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "ingresskobidemo"
}

locals {
  backend_address_pool_name      = "${azurerm_virtual_network.hub_vnet.name}-nginx-pool"
  frontend_port_name             = "${azurerm_virtual_network.hub_vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.hub_vnet.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.hub_vnet.name}-helloWorld-http-setting"
  listener_name                  = "${azurerm_virtual_network.hub_vnet.name}-helloWorld-http-listener"
  request_routing_rule_name      = "${azurerm_virtual_network.hub_vnet.name}-helloWorld-rule"
  redirect_configuration_name    = "${azurerm_virtual_network.hub_vnet.name}-rdrcfg"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "kobi-appgateway"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.front_subnet.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.gw_pip.id
  }

  backend_address_pool {
    name         = local.backend_address_pool_name
    ip_addresses = ["10.224.0.10"]
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    host_name             = "ingresskobidemo.westeurope.cloudapp.azure.com"
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
    host_name                      = "ingresskobidemo.westeurope.cloudapp.azure.com"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 200
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}