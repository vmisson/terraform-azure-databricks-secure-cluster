resource "azurerm_resource_group" "resource_group" {
  name     = "shared-services"
  location = var.location
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "shared-services-vnet"
  address_space       = ["10.250.0.0/23"]
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet" "subnet_private_endpoint" {
  name                              = "private-endpoint-subnet"
  resource_group_name               = azurerm_resource_group.resource_group.name
  virtual_network_name              = azurerm_virtual_network.virtual_network.name
  address_prefixes                  = ["10.250.0.0/24"]
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_virtual_network" "virtual_network_hub" {
  name                = "hub-vnet"
  address_space       = ["10.252.0.0/23"]
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet" "subnet_jumphost" {
  name                 = "jumphost-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network_hub.name
  address_prefixes     = ["10.252.0.0/24"]
}

resource "azurerm_virtual_network_peering" "hub-to-shared" {
  name                      = "hub-to-shared"
  resource_group_name       = azurerm_resource_group.resource_group.name
  virtual_network_name      = azurerm_virtual_network.virtual_network_hub.name
  remote_virtual_network_id = azurerm_virtual_network.virtual_network.id
}

resource "azurerm_virtual_network_peering" "shared-to-hub" {
  name                      = "shared-to-hub"
  resource_group_name       = azurerm_resource_group.resource_group.name
  virtual_network_name      = azurerm_virtual_network.virtual_network.name
  remote_virtual_network_id = azurerm_virtual_network.virtual_network_hub.id
}

resource "azurerm_network_interface" "jumphost_nic" {
  name                = "jumphost-nic"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name


  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_jumphost.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_windows_virtual_machine" "jumphost" {
  name                = "jumphost"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  size           = "Standard_D2s_v3"
  admin_username = var.username
  admin_password = random_password.password.result
  network_interface_ids = [
    azurerm_network_interface.jumphost_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "microsoftwindowsdesktop"
    offer     = "windows-11"
    sku       = "win11-24h2-pro"
    version   = "latest"
  }
}

resource "azurerm_public_ip" "public_ip" {
  name                = "jumphost-pip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "network_nsg" {
  name                = "jumphost-nsg"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  security_rule {
    name                       = "A-IN-ANY-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.subnet_jumphost.id
  network_security_group_id = azurerm_network_security_group.network_nsg.id
}

resource "azurerm_private_dns_zone" "private_dns_zone_azuredatabricks" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_virtual_network_link" {
  name                  = "azuredatabricks-to-hub"
  resource_group_name   = azurerm_resource_group.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone_azuredatabricks.name
  virtual_network_id    = azurerm_virtual_network.virtual_network_hub.id
}
