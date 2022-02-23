# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "morpheusVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    tags = {
        environment = "Morpheus Deployment"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "morpheusSubnet"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "morpheusPublicIP"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.myterraformgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Morpheus Deployment"
    }
}

data "azurerm_public_ip" "myterraformpublicip" {
    name                 = azurerm_public_ip.myterraformpublicip.name
    resource_group_name  = azurerm_public_ip.myterraformpublicip.resource_group_name
}

