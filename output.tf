output "jumphost_public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "username" {
  value = var.username
}

output "password" {
  value     = random_password.password.result
  sensitive = true
}