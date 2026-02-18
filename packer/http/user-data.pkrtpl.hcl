#cloud-config
# docs: https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html
autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: us
  source:
    id: ubuntu-server-minimal
  network:
    version: 2
    ethernets:
      any:
        match:
          name: en*
        dhcp4: true
  storage:
    layout:
      name: lvm
  identity:
    hostname: ubuntu-template
    username: ubuntu
    password: ${vm_password_hash}
  ssh:
    install-server: true
    authorized-keys:
      - ${ssh_public_key}
    allow-pw: false
  packages:
    - nfs-common
    - qemu-guest-agent
    - sudo
  user_data:
    package_upgrade: false
  updates: security
  timezone: Etc/UTC
  late-commands:
    - echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/adminuser
    - chmod 440 /target/etc/sudoers.d/adminuser
    - curtin in-target -- mkdir -p /mnt/storage
    - curtin in-target -- bash -c 'echo "${nfs_server}:/mnt/storage /mnt/storage nfs defaults 0 0" >> /etc/fstab'
