resource "azurerm_resource_group" "tfe_network" {
  name     = "${var.environment}-tfe-network"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "tfe" {
  name                = "${var.environment}-tfe-vnet"
  location            = "${azurerm_resource_group.tfe_network.location}"
  resource_group_name = "${azurerm_resource_group.tfe_network.name}"
  address_space       = ["10.0.0.0/16"]

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_network_security_group" "tfe" {
  name                = "${var.environment}-tfe-nsg"
  resource_group_name = "${azurerm_resource_group.tfe_network.name}"
  location            = "${var.location}"

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_subnet" "tfe" {
  name                      = "${var.environment}-tfe-subnet"
  resource_group_name       = "${azurerm_resource_group.tfe_network.name}"
  virtual_network_name      = "${azurerm_virtual_network.tfe.name}"
  address_prefix            = "10.0.0.0/24"
  service_endpoints         = ["Microsoft.Sql", "Microsoft.Storage"]
  network_security_group_id = "${azurerm_network_security_group.tfe.id}"
}

module "storage" {
  source = "../modules/storage"

  location    = "${var.location}"
  environment = "${var.environment}"
}

module "tfe" {
  source = "../"

  location                          = "${var.location}"
  environment                       = "${var.environment}"
  subnet_id                         = "${azurerm_subnet.tfe.id}"
  ssh_public_key                    = "${file("${path.module}/ssh/tfe.pub")}"
  boot_diagnostics_storage_endpoint = "${module.storage.storage_endpoint}"
  tfe_fqdn                          = "${var.tfe_fqdn}"
  vm_size                           = "Standard_F2s_v2"
  vm_os_disk_type                   = "Premium_LRS"
}
