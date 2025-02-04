module "databricks-1" {
  source = "./modules/adb-private"

  prefix                                  = "app1"
  virtual_network_address_space           = "10.0.0.0/23"
  subnet_public_address_prefixes          = "10.0.0.0/24"
  subnet_private_address_prefixes         = "10.0.1.0/24"
  subnet_private_endpoint_id              = azurerm_subnet.subnet_private_endpoint.id
  private_dns_zone_id                     = azurerm_private_dns_zone.private_dns_zone_azuredatabricks.id
  private_endpoint_databricks_ui_api      = true
  private_endpoint_browser_authentication = false
}

module "databricks-2" {
  source = "./modules/adb-private"

  prefix                                  = "app2"
  virtual_network_address_space           = "10.0.2.0/23"
  subnet_public_address_prefixes          = "10.0.2.0/24"
  subnet_private_address_prefixes         = "10.0.3.0/24"
  subnet_private_endpoint_id              = azurerm_subnet.subnet_private_endpoint.id
  private_dns_zone_id                     = azurerm_private_dns_zone.private_dns_zone_azuredatabricks.id
  private_endpoint_databricks_ui_api      = true
  private_endpoint_browser_authentication = false
}

module "databricks-auth" {
  source = "./modules/adb-private"

  prefix                                  = "private-web-auth"
  virtual_network_address_space           = "10.0.4.0/23"
  subnet_public_address_prefixes          = "10.0.4.0/24"
  subnet_private_address_prefixes         = "10.0.5.0/24"
  subnet_private_endpoint_id              = azurerm_subnet.subnet_private_endpoint.id
  private_dns_zone_id                     = azurerm_private_dns_zone.private_dns_zone_azuredatabricks.id
  private_endpoint_databricks_ui_api      = false
  private_endpoint_browser_authentication = true
  databricks_workspace_lock               = true
}