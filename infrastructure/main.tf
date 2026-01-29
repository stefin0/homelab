resource "proxmox_virtual_environment_vm" "nodes" {
  for_each = var.vms

  node_name = var.target_node
  vm_id     = each.value.id

  name        = each.key
  description = "Managed by Terraform. Tags: ${join(", ", each.value.tags)}"
  tags        = each.value.tags
  on_boot     = true

  bios    = "ovmf"
  machine = "q35"

  efi_disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    type         = "4m"

  }

  # --- Cloning from Packet Template ---
  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  agent {
    enabled = true
  }

  # --- Compute Resources ---
  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    interface   = "scsi0"
    file_format = "raw"
    iothread    = true
    discard     = "on"
    size        = each.value.disk_size
  }

  # --- Initialization (Cloud-init) ---
  initialization {
    ip_config {
      ipv4 {
        address = each.value.ip_cidr
        gateway = each.value.gateway
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }
  }

  network_device {
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [
      network_device,
    ]
  }
}
