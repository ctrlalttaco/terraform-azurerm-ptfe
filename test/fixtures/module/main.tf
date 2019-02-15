/*------------------------------------------------------------------------------
  Provider
  Use the following ENV vars:
    ARM_SUBSCRIPTION_ID
    ARM_CLIENT_ID
    ARM_CLIENT_SECRET
    ARM_TENANT_ID
------------------------------------------------------------------------------*/
provider "azurerm" {
  version = "~> 1.21.0"
}

locals {
  location                      = "West US"
  namespace                     = "kitchen-test-ptfe"
  ptfe_postgresql_firewall_rule = "kitchen-test-ptfe-postgresql-firewall-rule"
}

#
# Build up the required network resources
#
resource "azurerm_resource_group" "network" {
  name     = "${local.namespace}-network-rg"
  location = "${local.location}"
}

resource "azurerm_virtual_network" "ptfe" {
  name                = "${local.namespace}-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${local.location}"
  resource_group_name = "${azurerm_resource_group.network.name}"
}

resource "azurerm_subnet" "ptfe" {
  name                 = "${local.namespace}-subnet"
  virtual_network_name = "${azurerm_virtual_network.ptfe.name}"
  resource_group_name  = "${azurerm_resource_group.network.name}"
  address_prefix       = "10.0.0.0/24"
}

resource "azurerm_public_ip" "ptfe" {
  name                = "${local.namespace}-public-ip"
  location            = "${local.location}"
  resource_group_name = "${azurerm_resource_group.network.name}"
  allocation_method   = "Static"
}

#
# Build up the required storage resources
#
resource "azurerm_resource_group" "storage" {
  name     = "${local.namespace}-storage-rg"
  location = "${local.location}"
}

resource "azurerm_postgresql_server" "ptfe" {
  name                = "${local.namespace}-postgresql-server"
  location            = "${local.location}"
  resource_group_name = "${azurerm_resource_group.storage.name}"

  sku {
    name     = "gp_gen5_8"
    capacity = 8
    tier     = "GeneralPurpose" # Case Sensitive
    family   = "Gen5"           # Case Sensitive
  }

  storage_profile {
    storage_mb            = 51200
    backup_retention_days = "7"
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = "postgres"
  administrator_login_password = "P0stGr3$QL"
  version                      = "9.6"
  ssl_enforcement              = "enabled"
}

resource "azurerm_postgresql_database" "ptfe" {
  name                = "ptfedb"
  resource_group_name = "${azurerm_resource_group.storage.name}"
  server_name         = "${azurerm_postgresql_server.ptfe.name}"
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

resource "azurerm_postgresql_firewall_rule" "ptfe" {
  name                = "${local.ptfe_postgresql_firewall_rule}"
  resource_group_name = "${azurerm_resource_group.storage.name}"
  server_name         = "${azurerm_postgresql_server.ptfe.name}"
  start_ip_address    = "0.0.0.0" # Allows access to internal Azure services
  end_ip_address      = "0.0.0.0" # Allows access to internal Azure services
}

resource "azurerm_storage_account" "ptfe" {
  name                     = "ptfestorageacct"
  location                 = "${local.location}"
  resource_group_name      = "${azurerm_resource_group.storage.name}"
  account_kind             = "BlobStorage" # Case Sensitive
  account_tier             = "standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "ptfe" {
  name                  = "ptfe-storage-container"
  resource_group_name   = "${azurerm_resource_group.storage.name}"
  storage_account_name  = "${azurerm_storage_account.ptfe.name}"
  container_access_type = "private"
}

resource "azurerm_storage_blob" "ptfe" {
  name                   = "ptfe-storage-blob"
  resource_group_name    = "${azurerm_resource_group.storage.name}"
  storage_account_name   = "${azurerm_storage_account.ptfe.name}"
  storage_container_name = "${azurerm_storage_container.ptfe.name}"
  type                   = "block"
}

#
# Bring up this module for TFE
#
module "ptfe" {
  source              = "../../../"
  location            = "${local.location}"
  resource_group_name = "${local.namespace}-ptfe"
  subnet_id           = "${azurerm_subnet.ptfe.id}"
  ssh_public_key      = "${file("~/.ssh/id_rsa.pub")}"
}
