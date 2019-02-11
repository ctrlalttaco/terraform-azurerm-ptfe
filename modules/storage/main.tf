resource "azurerm_resource_group" "terraform" {
  name     = "${var.environment}-tfe-storage"
  location = "${var.location}"
}

resource "random_id" "storage_id" {
  byte_length = 8
}

resource "azurerm_storage_account" "terraform" {
  name                      = "tfe${random_id.storage_id.hex}"
  resource_group_name       = "${azurerm_resource_group.terraform.name}"
  location                  = "${var.location}"
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_storage_container" "application" {
  name                  = "application"
  resource_group_name   = "${azurerm_resource_group.terraform.name}"
  storage_account_name  = "${azurerm_storage_account.terraform.name}"
  container_access_type = "private"
}

resource "azurerm_storage_container" "bootstrap" {
  name                  = "bootstrap"
  resource_group_name   = "${azurerm_resource_group.terraform.name}"
  storage_account_name  = "${azurerm_storage_account.terraform.name}"
  container_access_type = "private"
}

output "storage_account_name" {
  value = "${azurerm_storage_account.terraform.name}"
}

output "storage_access_key" {
  value = "${azurerm_storage_account.terraform.primary_access_key}"
}

output "storage_endpoint" {
  value = "${azurerm_storage_account.terraform.primary_blob_endpoint}"
}

output "application_storage_container_name" {
  value = "${azurerm_storage_container.application.name}"
}

output "bootstrap_storage_container_name" {
  value = "${azurerm_storage_container.bootstrap.name}"
}
