

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
    name                  = var.instance_name
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

    computer_name  = var.host_name
    admin_username = "morpheususer"
    admin_password = "<%=cypher.readPassword('password/15/morpheususer')%>"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "morpheususer"
        public_key     = file(var.public_key_path)
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Morpheus Deployment"
    }

#    provisioner "remote-exec" {
#       inline = [ 
#         "<%=cloudConfig.agentInstall%>"
#         "sudo dnf install wget -y",
#         "wget https://downloads.morpheusdata.com/files/morpheus-appliance-5.3.2-1.el8.x86_64.rpm" ,
#         "sudo rpm -i morpheus-appliance-5.3.2-1.el8.x86_64.rpm",
#         "sudo morpheus-ctl reconfigure"
#       ]
#       connection {
#          type        = "ssh"
#          user        = "morpheususer"
#          private_key = file(var.private_key_path)
#          host        = self.public_ip_address
#       }
#    }
}
