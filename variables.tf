# Input Variables
variable "client_secret" {}

variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  default = "~/.ssh/id_rsa"
}

variable "instance_name" {
  default = "MorpheusVM"
}

variable "host_name" {
  default = "Morpheusvm"
}

# Output Variables
output "public_ips" {
  value = data.azurerm_public_ip.myterraformpublicip.ip_address
}
