terraform {
  required_version = "~> 0.11.11"
}

provider "azurerm" {
  version = "~> 1.21.0"
}

resource "azurerm_resource_group" "tfe" {
  name     = "${var.environment}-tfe"
  location = "${var.location}"
}

data "template_file" "custom_data" {
  template = "${file("${path.module}/templates/custom_data.tpl")}"

  vars {
    lb_private_ip_address = "${azurerm_lb.tfe_private.private_ip_address}"
  }
}

resource "azurerm_virtual_machine_scale_set" "tfe" {
  name                = "${var.environment}-tfe"
  location            = "${azurerm_resource_group.tfe.location}"
  resource_group_name = "${azurerm_resource_group.tfe.name}"
  upgrade_policy_mode = "manual"

  sku {
    name     = "${var.vm_size}"
    tier     = "standard"
    capacity = 1
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = "${var.boot_diagnostics_storage_endpoint}"
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${var.vm_os_disk_type}"
  }

  os_profile {
    computer_name_prefix  = "tfe"
    admin_username = "tfe"
    admin_password = "cannotbeblank"
    custom_data    = "${data.template_file.custom_data.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/tfe/.ssh/authorized_keys"
      key_data = "${var.ssh_public_key}"
    }
  }

  network_profile {
    name    = "tfe-network-profile"
    primary = true

    ip_configuration {
      name                                   = "tfe-ip-config"
      primary                                = true
      subnet_id                              = "${var.subnet_id}"
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.tfe_private.id}"]
      application_security_group_ids         = ["${azurerm_application_security_group.tfe.id}"]
    }
  }

  tags {
    environment = "${var.environment}"
  }
}

locals {
  private_frontend_pool_name = "tfe-private-frontend"
}

resource "azurerm_lb" "tfe_private" {
  name                = "${var.environment}-tfe-private-lb"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.tfe.name}"

  frontend_ip_configuration {
    name      = "${local.private_frontend_pool_name}"
    subnet_id = "${var.subnet_id}"
  }

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_lb_backend_address_pool" "tfe_private" {
  resource_group_name = "${azurerm_resource_group.tfe.name}"
  loadbalancer_id     = "${azurerm_lb.tfe_private.id}"
  name                = "tfe-private-bep"
}

resource "azurerm_lb_probe" "tfe_private_setup" {
  name                = "tfe-private-setup-probe"
  resource_group_name = "${azurerm_resource_group.tfe.name}"
  loadbalancer_id     = "${azurerm_lb.tfe_private.id}"
  port                = 8800
}

resource "azurerm_lb_probe" "tfe_private_http" {
  name                = "tfe-private-http-probe"
  resource_group_name = "${azurerm_resource_group.tfe.name}"
  loadbalancer_id     = "${azurerm_lb.tfe_private.id}"
  port                = 80
}

resource "azurerm_lb_probe" "tfe_private_https" {
  name                = "tfe-private-https-probe"
  resource_group_name = "${azurerm_resource_group.tfe.name}"
  loadbalancer_id     = "${azurerm_lb.tfe_private.id}"
  port                = 443
}

resource "azurerm_lb_rule" "tfe_private_http" {
  name                           = "tfe-private-lb-http-rule"
  resource_group_name            = "${azurerm_resource_group.tfe.name}"
  loadbalancer_id                = "${azurerm_lb.tfe_private.id}"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  probe_id                       = "${azurerm_lb_probe.tfe_private_http.id}"
  frontend_ip_configuration_name = "${local.private_frontend_pool_name}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.tfe_private.id}"
}

resource "azurerm_lb_rule" "tfe_private_https" {
  name                           = "tfe-lb-https-rule"
  resource_group_name            = "${azurerm_resource_group.tfe.name}"
  loadbalancer_id                = "${azurerm_lb.tfe_private.id}"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  probe_id                       = "${azurerm_lb_probe.tfe_private_https.id}"
  frontend_ip_configuration_name = "${local.private_frontend_pool_name}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.tfe_private.id}"
}

resource "azurerm_lb_rule" "tfe_private_setup" {
  name                           = "tfe-lb-setup-rule"
  resource_group_name            = "${azurerm_resource_group.tfe.name}"
  loadbalancer_id                = "${azurerm_lb.tfe_private.id}"
  protocol                       = "Tcp"
  frontend_port                  = 8800
  backend_port                   = 8800
  probe_id                       = "${azurerm_lb_probe.tfe_private_setup.id}"
  frontend_ip_configuration_name = "${local.private_frontend_pool_name}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.tfe_private.id}"
}

resource "azurerm_application_security_group" "tfe" {
  name                = "${var.environment}-tfe-asg"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.tfe.name}"

  tags {
    environment = "${var.environment}"
  }
}
