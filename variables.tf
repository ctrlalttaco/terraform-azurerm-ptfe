# Required inputs
variable "location" {
  description = "Location (Region) of Azure"
  type        = "string"
}

variable "resource_group_name" {
  description = "Name of the resource group to place the TFE resources"
  type = "string"
}

variable "subnet_id" {
  description = "ID of the subnet to place the VMs in"
  type        = "string"
}

variable "ssh_public_key" {
  description = "SSH key for the TFE server"
  type        = "string"
}

# Optional inputs
variable "app_security_group_name" {
  default = "ptfe-app-security-group"
}
variable "boot_diagnostics_storage_endpoint" {
  description = "Endpoint to place the boot diagnostics"
  type        = "string"
  default     = ""
}

variable "enable_boot_diagnostics" {
  description = "a variable set to true or false depending on whether boot diagnostics should be enabled or not"
  type        = "string"
  default     = false
}

variable "lb_name" {
  default = "ptfe-lb"
}

variable "vm_scale_set_name" {
  default = "ptfe-scale-set"
}

variable "vm_os_disk_type" {
  description = "Case sensitive operating system disk type for the VM"
  type        = "string"
  default     = "Premium_LRS"
}

variable "vm_size" {
  description = "VM size"
  type        = "string"
  default     = "Standard_F4s_v2"
}
