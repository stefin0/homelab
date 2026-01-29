# --- API Configuration ---
variable "proxmox_api_url" {
  type = string
}
variable "proxmox_api_token_id" {
  type      = string
  sensitive = true
}
variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}
variable "insecure_skip_tls_verify" {
  type = bool
}

# --- VM Configuration ---
variable "vm_id" {
  type = number
}
variable "vm_name" {
  type = string
}
variable "disk_size" {
  type = string
}
variable "cores" {
  type = number
}
variable "memory" {
  type = number
}

# --- ISO Configuration
variable "iso_url" {
  type = string
}

variable "iso_checksum" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "iso_filename" {
  type = string
}

variable "vm_password_hash" {
  type = string
}
