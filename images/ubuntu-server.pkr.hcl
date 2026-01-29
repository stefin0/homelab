packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "ubuntu-server" {
  # --- Connection Details ---
  proxmox_url = var.proxmox_api_url
  username    = var.proxmox_api_token_id
  token       = var.proxmox_api_token_secret

  insecure_skip_tls_verify = var.insecure_skip_tls_verify

  # --- VM Settings ---
  node                 = "proxmox"
  vm_id                = var.vm_id
  vm_name              = var.vm_name
  template_description = "Ubuntu built on ${timestamp()}"

  cpu_type = "host"
  cores    = var.cores
  memory   = var.memory

  bios    = "ovmf"
  machine = "q35"

  efi_config {
    efi_storage_pool  = "local-lvm"
    pre_enrolled_keys = false
    efi_type          = "4m"
  }

  rng0 {
    source    = "/dev/urandom"
    max_bytes = 1024
    period    = 1000
  }

  # --- ISO Configuration ---
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
      ssh_key       = var.ssh_public_key,
      password_hash = var.vm_password_hash
    })
  }
  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  # --- Disk & Network ---
  scsi_controller = "virtio-scsi-single"

  disks {
    type         = "scsi"
    disk_size    = var.disk_size
    storage_pool = "local-lvm"
    cache_mode   = "writeback"
    discard      = true
  }

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # --- Boot Configuration ---
  boot = "order=scsi0;ide0;net0"
  boot_command = [
    "<esc><wait>",
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ quiet<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  # --- Communicator ---
  ssh_username         = "ubuntu"
  ssh_timeout          = "15m"
  ssh_private_key_file = "~/.ssh/id_ed25519"
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

      # 1. Remove SSH Host Keys (Force regeneration on next boot)
      "sudo rm -f /etc/ssh/ssh_host_*",

      # 2. Reset Machine ID (Prevents duplicate DHCP leases)
      "sudo truncate -s 0 /etc/machine-id",
      "sudo rm /var/lib/dbus/machine-id",
      "sudo ln -s /etc/machine-id /var/lib/dbus/machine-id",

      # 3. Clean Cloud-Init (So it runs again on the clone)
      "sudo cloud-init clean",
      "sudo rm -rf /var/lib/cloud/*",

      # 4. Clean Package Manager cache (Save space)
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*",

      # 5. Clear Audit logs and History
      "sudo truncate -s 0 /var/log/wtmp",
      "sudo truncate -s 0 /var/log/lastlog",
      "rm -f ~/.bash_history",

      "sudo sync"
    ]
  }
}
