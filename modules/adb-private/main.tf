locals {
  prefix = coalesce(var.prefix, random_string.prefix.result)
}

resource "random_string" "prefix" {
  special = false
  upper   = false
  length  = 6
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${local.prefix}-${var.resource_group_name}"
  location = var.location
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "${local.prefix}-${var.virtual_network_name}"
  address_space       = [var.virtual_network_address_space]
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet" "subnet_public" {
  name                 = "${local.prefix}-${var.subnet_public_name}"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = [var.subnet_public_address_prefixes]

  delegation {
    name = "${local.prefix}-subnet-public-delegation"

    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
      name = "Microsoft.Databricks/workspaces"
    }
  }
}

resource "azurerm_subnet" "subnet_private" {
  name                 = "${local.prefix}-${var.subnet_private_name}"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = [var.subnet_private_address_prefixes]

  delegation {
    name = "${local.prefix}-subnet-private-delegation"

    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
      name = "Microsoft.Databricks/workspaces"
    }
  }
}

resource "azurerm_network_security_group" "network_security_group" {
  name                = "${local.prefix}-${var.network_security_group_name}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet_network_security_group_association" "association_public" {
  subnet_id                 = azurerm_subnet.subnet_public.id
  network_security_group_id = azurerm_network_security_group.network_security_group.id
}

resource "azurerm_subnet_network_security_group_association" "association_private" {
  subnet_id                 = azurerm_subnet.subnet_private.id
  network_security_group_id = azurerm_network_security_group.network_security_group.id
}

resource "azurerm_databricks_workspace" "databricks_workspace" {
  name                        = "${local.prefix}-${var.databricks_workspace_name}"
  location                    = azurerm_resource_group.resource_group.location
  resource_group_name         = azurerm_resource_group.resource_group.name
  sku                         = var.databricks_workspace_sku
  managed_resource_group_name = "${local.prefix}-managed-${var.resource_group_name}"

  public_network_access_enabled         = false
  network_security_group_rules_required = "NoAzureDatabricksRules"

  custom_parameters {
    no_public_ip        = true
    public_subnet_name  = azurerm_subnet.subnet_public.name
    private_subnet_name = azurerm_subnet.subnet_private.name
    virtual_network_id  = azurerm_virtual_network.virtual_network.id

    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.association_public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.association_private.id
  }
}

resource "azurerm_private_endpoint" "databricks" {
  count               = var.private_endpoint_databricks_ui_api ? 1 : 0
  name                = "${local.prefix}-databricks-pe"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  subnet_id           = var.subnet_private_endpoint_id

  private_service_connection {
    name                           = "${local.prefix}-ui-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_databricks_workspace.databricks_workspace.id
    subresource_names              = ["databricks_ui_api"]
  }

  private_dns_zone_group {
    name                 = "${local.prefix}-ui-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

resource "azurerm_private_endpoint" "auth" {
  count               = var.private_endpoint_browser_authentication ? 1 : 0
  name                = "${local.prefix}-aadauthpe"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  subnet_id           = var.subnet_private_endpoint_id

  private_service_connection {
    name                           = "${local.prefix}-auth-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_databricks_workspace.databricks_workspace.id
    subresource_names              = ["browser_authentication"]
  }

  private_dns_zone_group {
    name                 = "${local.prefix}-auth-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

resource "azurerm_management_lock" "lock" {
  count = var.databricks_workspace_lock ? 1 : 0
  # https://learn.microsoft.com/en-us/azure/databricks/administration-guide/cloud-configurations/azure/private-link#--step-4-configure-dns-to-support-sso-authentication-flow-required-for-ui-access
  name       = "${local.prefix}-databricks-lock"
  scope      = azurerm_databricks_workspace.databricks_workspace.id
  lock_level = "CanNotDelete"
  notes      = "Locked by Terraform"
}