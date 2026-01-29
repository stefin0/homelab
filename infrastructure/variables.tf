variable "proxmox_api_url" {
  description = "The URL for the Proxmox API (e.g., https://192.168.x.x:8006/api2/json)"
  type        = string
}
variable "proxmox_api_token_id" {
  description = "The Token ID (e.g., root@pam!terraform)"
  type        = string
  sensitive   = true
}
variable "proxmox_api_token_secret" {
  description = "The Secret UUID for the API Token"
  type        = string
  sensitive   = true
}

# --- Target Node Settings ---
variable "target_node" {
  description = "Proxmox node to deploy VMs onto"
  type        = string
}
variable "template_vm_id" {
  description = "The ID of the Packer template to clone"
  type        = number
}

# --- Scalability Settings ---
variable "vms" {
  description = "Map of VMs to create with their specific configurations"
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
# --- SSH ---
variable "ssh_public_key" {
  description = "Path to the public SSH key"
  type        = string
}
