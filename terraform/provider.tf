# docs: https://registry.terraform.io/providers/bpg/proxmox/latest/docs
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.73.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_url
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = true
  ssh {
    agent    = true
    username = "root"
  }
}
