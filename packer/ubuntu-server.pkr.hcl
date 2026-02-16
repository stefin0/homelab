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
  # Proxmox Connection
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  insecure_skip_tls_verify = var.insecure_skip_tls_verify

  # VM Identity
  node                 = var.node_name
  vm_id                = var.template_vm_id
  vm_name              = var.template_vm_name
  tags                 = "ubuntu;template"
  template_description = "Ubuntu built on ${timestamp()}"

  # Hardware
  bios     = "ovmf"
  machine  = "q35"
  os       = "l26"
  cpu_type = "host"
  cores    = var.cores
  memory   = var.memory

  # EFI
  efi_config {
    efi_storage_pool  = var.storage_pool
    pre_enrolled_keys = false
  }

  # RNG Device
  rng0 {
    source    = "/dev/urandom"
    max_bytes = 1024
    period    = 1000
  }

  # SCSI Controller
  scsi_controller = "virtio-scsi-single"

  # Disks
  disks {
    type         = "scsi"
    disk_size    = var.disk_size
    storage_pool = var.storage_pool
    cache_mode   = "writeback"
    discard      = true
    io_thread    = true
  }

  # Network
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Boot ISO
  boot_iso {
    type             = "ide"
    iso_file         = "local:iso/${var.iso_filename}"
    iso_checksum     = var.iso_checksum
    iso_storage_pool = "local"
    unmount          = true
  }

  # Cloud-Init
  cloud_init              = true
  cloud_init_storage_pool = var.storage_pool

  # HTTP Server (for cloud-init user-data)
  http_content = {
    "/meta-data" = ""
    "/user-data" = templatefile("${path.root}/http/user-data.pkrtpl.hcl", {
      nfs_server       = var.nfs_server
      ssh_public_key   = file(var.ssh_public_key_file)
      vm_password_hash = var.vm_password_hash
    })
  }

  # Boot Order & Command
  boot = "order=scsi0;ide0;net0"
  boot_command = [
    "<esc><wait>",
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ quiet<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  # SSH Communicator
  ssh_username         = "ubuntu"
  ssh_timeout          = "15m"
  ssh_private_key_file = var.ssh_private_key_file
}

build {
  sources = ["source.proxmox-iso.ubuntu-server"]

  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init...'",
      "cloud-init status --wait"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo 'Starting Cleanup...'",
      "sudo rm -f /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo rm /var/lib/dbus/machine-id",
      "sudo ln -s /etc/machine-id /var/lib/dbus/machine-id",
      "sudo cloud-init clean",
      "sudo rm -rf /var/lib/cloud/*",
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*",
      "sudo truncate -s 0 /var/log/wtmp",
      "sudo truncate -s 0 /var/log/lastlog",
      "rm -f ~/.bash_history",
      "sudo sync"
    ]
  }
}

