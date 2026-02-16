# docs: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm
resource "proxmox_virtual_environment_vm" "nodes" {
  for_each = var.vms

  node_name = var.node_name
  vm_id     = each.value.id

  name        = each.key
  description = "Managed by Terraform. Tags: ${join(", ", each.value.tags)}"
  tags        = each.value.tags
  on_boot     = true

  bios    = "ovmf"
  machine = "q35"

  efi_disk {
    datastore_id = var.storage_pool
    file_format  = "raw"
    type         = "4m"
  }

  # Cloning from Packer Template
  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  agent {
    enabled = true
  }

  # Compute Resources
  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    interface    = "scsi0"
    datastore_id = var.storage_pool
    file_format  = "raw"
    iothread     = true
    discard      = "on"
    size         = each.value.disk_size
  }

  dynamic "disk" {
    for_each = { for idx, d in each.value.data_disks : idx => d }
    content {
      interface    = "scsi${disk.key + 1}"
      size         = disk.value.size
      datastore_id = disk.value.datastore
      file_format  = "raw"
      iothread     = true
      discard      = "on"
    }
  }

  # Initialization (Cloud-init)
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

  network_device {
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [
      network_device,
    ]
  }
}
