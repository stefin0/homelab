# docs: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm
resource "proxmox_virtual_environment_vm" "nodes" {
  for_each = var.vms

  # Identity
  vm_id       = each.value.id
  name        = each.key
  description = "Managed by Terraform. Tags: ${join(", ", each.value.tags)}"
  tags        = each.value.tags

  # Placement
  node_name = var.node_name

  # Firmware & Boot
  bios    = "ovmf"
  machine = "q35"

  efi_disk {
    datastore_id = var.storage_pool
    type         = "4m"
  }

  operating_system {
    type = "l26"
  }

  # Cloning
  clone {
    vm_id = var.template_vm_id
  }

  # Compute
  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  # Storage
  disk {
    interface    = "scsi0"
    datastore_id = var.storage_pool
    iothread     = true
    discard      = "on"
    size         = each.value.disk_size
  }

  # Guest Agent
  agent {
    enabled = true
  }

  stop_on_destroy = true

  # Cloud-init
  initialization {
    ip_config {
      ipv4 {
        address = each.value.ip_cidr
        gateway = each.value.gateway
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [file(var.ssh_public_key_file)]
    }
  }
}