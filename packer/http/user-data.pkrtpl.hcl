#cloud-config
# docs: https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html
autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: us
  network:
    network:
      version: 2
      ethernets:
        any:
          match:
            name: en*
          dhcp4: true
  storage:
    layout:
      name: direct
  identity:
    hostname: ubuntu-template
    username: ubuntu
    password: ${vm_password_hash}
  ssh:
    install-server: true
    authorized-keys:
      - ${ssh_public_key}
  packages:
    - nfs-common
    - qemu-guest-agent
    - sudo
  user_data:
    package_upgrade: false
  late-commands:
    - echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/adminuser
    - mkdir -p /target/mnt/storage
    - echo "${nfs_server}:/mnt/storage /mnt/storage nfs defaults 0 0" >> /target/etc/fstab
