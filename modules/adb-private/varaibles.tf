variable "prefix" {
  type    = string
  default = ""
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "resource_group_name" {
  type    = string
  default = "databricks"
}

variable "virtual_network_name" {
  type    = string
  default = "databricks-vnet"
}

variable "virtual_network_address_space" {
  type    = string
  default = "10.0.0.0/23"
}

variable "subnet_public_name" {
  type = string
  default = "databricks-public-subnet"
}

variable "subnet_public_address_prefixes" {
  type = string
  default = "10.0.0.0/24"
}

variable "subnet_private_name" {
  type = string
  default = "databricks-private-subnet"
}

variable "subnet_private_address_prefixes" {
  type = string
  default = "10.0.1.0/24"
}

variable "network_security_group_name" {
  type = string
  default = "databricks-nsg"
}

variable "databricks_workspace_name" {
    type = string
    default = "databricks-workspace"
}

variable "databricks_workspace_sku" {
    type = string
    default = "premium"
}

variable "subnet_private_private_endpoint_id" {
    type = string
}

variable "private_dns_zone_id" {
    type = string
}

variable "private_endpoint_databricks_ui_api" {
    type = bool
    default = true
}

variable "private_endpoint_browser_authentication" {
    type = bool
    default = false
}

variable "databricks_workspace_lock" {
    type = bool
    default = false
}
