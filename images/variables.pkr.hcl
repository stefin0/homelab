# Proxmox Connection Settings
variable "proxmox_url" {
  type        = string
  description = "The full URL of the Proxmox API (e.g., https://192.168.1.10:8006/api2/json)."
}
variable "proxmox_username" {
  type        = string
  sensitive   = true
  description = "The username for authenticating with the Proxmox API (e.g., root@pam)."
}
variable "proxmox_password" {
  type        = string
  sensitive   = true
  description = "The password for the Proxmox user."
}
variable "insecure_skip_tls_verify" {
  type        = bool
  default     = true
  description = "Skip TLS certificate validation for the Proxmox API."
}

# Virtual Machine Hardware Settings
variable "template_vm_id" {
  type        = number
  description = "The unique ID to assign to the template VM."
}
variable "template_vm_name" {
  type        = string
  description = "The name of the resulting VM template."
}
variable "node_name" {
  type        = string
  description = "The Proxmox node name where resources will be provisioned."
}
variable "cores" {
  type        = number
  description = "Number of CPU cores to allocate for the build."
}
variable "memory" {
  type        = number
  description = "Amount of RAM (in MB) to allocate for the build."
}
variable "disk_size" {
  type        = string
  description = "Size of the OS disk (e.g., '20G')."
}
variable "storage_pool" {
  type        = string
  default     = "local-lvm"
  description = "The Proxmox storage pool ID where the VM disk will be stored."
}

# ISO & Installation Media
variable "iso_checksum" {
  type        = string
  description = "The checksum (SHA256) of the ISO file."
}
variable "iso_filename" {
  type        = string
  description = "The filename to save the ISO as on the Proxmox host."
}

# Provisioning & Authentication
variable "ssh_public_key_file" {
  type        = string
  description = "Path to the local public SSH key to inject into the authorized_keys."
}
variable "ssh_private_key_file" {
  type        = string
  description = "Path to the local private SSH key used by Packer to connect during build."
}
variable "vm_password_hash" {
  type        = string
  sensitive   = true
  description = "The hashed password for the default user (generated via 'openssl passwd -6')."
}
