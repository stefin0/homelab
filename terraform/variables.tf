# Proxmox Provider Configuration
variable "proxmox_url" {
  type        = string
  description = "The full URL of the Proxmox API (e.g., https://192.168.1.10:8006/)."
}
variable "proxmox_username" {
  type        = string
  sensitive   = true
  description = "The username for authenticating with the Proxmox API."
}
variable "proxmox_password" {
  type        = string
  sensitive   = true
  description = "The password for the Proxmox user."
}

# Cluster & Template Settings
variable "node_name" {
  type        = string
  description = "The Proxmox node name where resources will be provisioned."
}
variable "template_vm_id" {
  type        = number
  description = "The ID of the Packer-generated template to clone."
}
variable "storage_pool" {
  type        = string
  default     = "local-lvm"
  description = "The default storage pool for OS disks if not specified otherwise."
}

# VM Definitions (Scalability)
variable "vms" {
  description = "Map of VM definitions including hardware specs, networking, and extra data disks."
  type = map(object({
    id        = number
    cores     = number
    memory    = number
    disk_size = number
    ip_cidr   = string
    gateway   = string
    tags      = list(string)
  }))
}

# Access & Security
variable "ssh_public_key_file" {
  type        = string
  description = "The path to the SSH public key to inject via Cloud-Init."
}
