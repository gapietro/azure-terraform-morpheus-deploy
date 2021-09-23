variable "client_secret" {
}

# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id             = "ac29218a-8545-4c3a-9a24-5b594020274c"
  client_id                   = "c83c1d9d-7d5f-4382-97cc-eeb47046ffd1"
  client_secret               = var.client_secret
  tenant_id                   = "b16e2942-acf7-4664-a827-c99d7e81a77d"
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "morpheusResourceGroup"
    location = "eastus"

    tags = {
        environment = "Morpheus Deployment"
    }
}

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

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "morpheusNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "HTTPS"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Morpheus Deployment"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "morpheusNIC"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.myterraformgroup.name

    ip_configuration {
        name                          = "morpheusNicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }

    tags = {
        environment = "Morpheus Deployment"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.myterraformnic.id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.myterraformgroup.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.myterraformgroup.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Morpheus Deployment"
    }
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { 
    value = tls_private_key.example_ssh.private_key_pem 
    sensitive = true
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
    name                  = "morpheusVM"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.myterraformgroup.name
    network_interface_ids = [azurerm_network_interface.myterraformnic.id]
    size                  = "Standard_D2s_v3"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Openlogic"
        offer     = "CentOS"
        sku       = "8_4-gen2"
        version   = "latest"
    }

    computer_name  = "morpheusvm"
    admin_username = "morpheususer"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "morpheususer"
        public_key     = file("~/.ssh/id_rsa.pub")
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Morpheus Deployment"
    }

    provisioner "remote-exec" {
       inline = [ 
         "sudo dnf install wget -y",
         "wget https://downloads.morpheusdata.com/files/morpheus-appliance-5.3.2-1.el8.x86_64.rpm" ,
         "sudo rpm -i morpheus-appliance-5.3.2-1.el8.x86_64.rpm",
         "sudo morpheus-ctl reconfigure"
       ]
       connection {
          type        = "ssh"
          user        = "morpheususer"
          private_key = file("~/.ssh/id_rsa")
          host        = self.public_ip_address
       }
    }
}
