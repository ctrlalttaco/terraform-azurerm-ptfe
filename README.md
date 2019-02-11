# PTFE Azure Module

## Required Input Variables

| Variable | Default Value | Description |
| -------- | ------------- | ----------- |
| location | None | Azure datacenter location |
| environment | None | Environment name to prefix to resources |
| subnet_id | None | Subnet ID to use for networking components |
| ssh_public_key | None | SSH public key content for TFE instances |
| diagnostics_storage_endpoint | None | Storage endpoint URL for boot diagnostics |
| tfe_fqdn | None | FQDN of endpoint to be used for TFE |
| vm_os_disk_type | Premium_LRS | Azure managed disk type for OS disk |
| vm_size | Standard_F4s_v2 | Azure VM image size |