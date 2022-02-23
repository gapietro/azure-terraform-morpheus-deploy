#Create Resource Group
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "morpheusResourceGroup"
    location = "eastus"

    tags = {
        environment = "Morpheus Deployment"
    }
}

