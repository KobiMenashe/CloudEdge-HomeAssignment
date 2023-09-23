# terraform {
#   backend "azurerm" {
#     resource_group_name  = "KobiAssignment"
#     storage_account_name = "sadevweu01"
#     container_name       = "tfstate"
#     key                  = "terraform.tfstate"
#   }
# }
 
# provider "azurerm" {
#   # The "feature" block is required for AzureRM provider 2.x.
#   # If you're using version 1.x, the "features" block is not allowed.
#   version = "~>2.0"
#   features {}
# }
 
# data "azurerm_client_config" "current" {}
 

data "azurerm_resource_group" "rg" {
  name = "KobiAssignment"
}

# Create AKS
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "kobi-aks"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "kobiaks1"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_A2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Create Virtual Network
resource "azurerm_virtual_network" "hub_vnet" {
  name                = "hub-vnet"
  address_space       = ["192.168.0.0/16"]
  location            = "westeurope"
  resource_group_name = data.azurerm_resource_group.rg.name
}
 
# Create Subnet
resource "azurerm_subnet" "hub_subnet" {
  name                 = "hub-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefix       = "192.168.0.0/24"
}
