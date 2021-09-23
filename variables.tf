output "public_ips" {
  value = data.azurerm_public_ip.myterraformpublicip.ip_address
}
