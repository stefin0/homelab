#cloud-config
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
    password: ${password_hash}
  ssh:
    install-server: true
    authorized-keys:
      - ${ssh_key}
  packages:
    - qemu-guest-agent
    - sudo
  user_data:
    package_upgrade: false
  late-commands:
    - echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/adminuser
