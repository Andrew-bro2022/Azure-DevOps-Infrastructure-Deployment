output "public_ip" {
  value = azurerm_public_ip.main.ip_address
  description = "The public IP of the VM"
}
