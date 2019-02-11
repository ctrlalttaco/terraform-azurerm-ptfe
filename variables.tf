variable "location" {}
variable "environment" {}
variable "subnet_id" {}
variable "ssh_public_key" {}
variable "boot_diagnostics_storage_endpoint" {}
variable "tfe_fqdn" {}
variable "vm_os_disk_type" {
  default = "Premium_LRS"
}

variable "vm_size" {
  default = "Standard_F4s_v2"
}
