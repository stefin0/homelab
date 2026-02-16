# docs: https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox
packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "ubuntu-server" {
  # Connection Details
  proxmox_url = var.proxmox_url
  username    = var.proxmox_username
  password    = var.proxmox_password

  insecure_skip_tls_verify = var.insecure_skip_tls_verify

  qemu_agent = true

  # VM Settings
  node                 = var.node_name
  vm_id                = var.template_vm_id
  vm_name              = var.template_vm_name
  template_description = "Ubuntu built on ${timestamp()}"

  cpu_type = "host"
  cores    = var.cores
  memory   = var.memory

  bios    = "ovmf"
  machine = "q35"

  efi_config {
    efi_storage_pool  = var.storage_pool
    pre_enrolled_keys = false
    efi_type          = "4m"
  }

  rng0 {
    source    = "/dev/urandom"
    max_bytes = 1024
    period    = 1000
  }

  # ISO Configuration
  boot_iso {
    type             = "ide"
    iso_file         = "local:iso/${var.iso_filename}"
    iso_checksum     = var.iso_checksum
    iso_storage_pool = "local"
    unmount          = true
  }

  http_content = {
    "/meta-data" = ""
    "/user-data" = templatefile("${path.root}/http/user-data.pkrtpl.hcl", {
      nfs_server       = var.nfs_server,
      ssh_public_key   = file(var.ssh_public_key_file),
      vm_password_hash = var.vm_password_hash
    })
  }
  cloud_init              = true
  cloud_init_storage_pool = var.storage_pool

  # Disk & Network
  scsi_controller = "virtio-scsi-single"

  disks {
    type         = "scsi"
    disk_size    = var.disk_size
    storage_pool = var.storage_pool
    cache_mode   = "writeback"
    discard      = true
  }

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Boot Configuration
  boot = "order=scsi0;ide0;net0"
  boot_command = [
    "<esc><wait>",
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ quiet<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  # Communicator
  ssh_username         = "ubuntu"
  ssh_timeout          = "15m"
  ssh_private_key_file = var.ssh_private_key_file
}

build {
  sources = ["source.proxmox-iso.ubuntu-server"]

  # Wait for cloud-init
  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init...'",
      "cloud-init status --wait"
    ]
  }

  # Cleanup
  provisioner "shell" {
    inline = [
      "echo 'Starting Cleanup...'",

      # Remove SSH Host Keys
      "sudo rm -f /etc/ssh/ssh_host_*",

      # Reset Machine ID
      "sudo truncate -s 0 /etc/machine-id",
      "sudo rm /var/lib/dbus/machine-id",
      "sudo ln -s /etc/machine-id /var/lib/dbus/machine-id",

      # Clean Cloud-Init
      "sudo cloud-init clean",
      "sudo rm -rf /var/lib/cloud/*",

      # Clean Package Manager cache
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*",

      # Clear Audit logs and History
      "sudo truncate -s 0 /var/log/wtmp",
      "sudo truncate -s 0 /var/log/lastlog",
      "rm -f ~/.bash_history",

      "sudo sync"
    ]
  }
}
