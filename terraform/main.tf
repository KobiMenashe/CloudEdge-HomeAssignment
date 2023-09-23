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
  # skip_provider_registration = true
  features {}
}

data "azurerm_client_config" "current" {}

# Data RG
data "azurerm_resource_group" "rg" {
  name = "KobiAssignment"
}

#Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "kobi-vnet"
  address_space       = ["192.168.0.0/16"]
  location            = "westeurope"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Create Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.1.0/24"]
}
