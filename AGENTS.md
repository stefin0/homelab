# AGENTS.md - Homelab Infrastructure Repository

## Overview

This is a homelab infrastructure-as-code repository using Ansible, Packer, Terraform, and Docker Compose to manage Proxmox VE and deployed services.

## Build & Deploy Commands

```bash
# Full pipeline (bootstrap -> build -> deploy)
make all

# Individual steps
make bootstrap   # Run Ansible playbooks against Proxmox host
make build       # Build golden image with Packer
make deploy      # Deploy VMs with Terraform

# Terraform commands
cd terraform && terraform init
cd terraform && terraform plan
cd terraform && terraform apply -auto-approve
cd terraform && terraform destroy

# Packer commands
cd packer && packer init .
cd packer && packer build .
cd packer && packer validate .

# Ansible commands
ansible-playbook -i "<host>," -u root ansible/bootstrap.yml
ansible-playbook --check --diff -i "<host>," ansible/bootstrap.yml  # Dry run
```

## Testing & Validation

```bash
# Validate Terraform
cd terraform && terraform validate

# Format Terraform
cd terraform && terraform fmt -recursive

# Validate Packer
cd packer && packer validate .

# Format Packer
cd packer && packer fmt .

# Check Ansible syntax
ansible-playbook --syntax-check -i "localhost," ansible/bootstrap.yml

# Ansible lint (if installed)
ansible-lint ansible/

# Dry run Ansible
ansible-playbook --check --diff -i "<host>," ansible/bootstrap.yml
```

## Project Structure

```
.
├── ansible/           # Ansible playbooks and roles
│   ├── bootstrap.yml
│   └── roles/
├── packer/            # Packer templates for VM images
│   ├── *.pkr.hcl
│   └── http/
├── terraform/         # Terraform for VM deployment
│   ├── *.tf
│   └── .terraform.lock.hcl
├── legacy/            # Docker Compose services
│   ├── traefik/
│   ├── jellyfin/
│   └── ...
├── Makefile           # Build orchestration
├── homelab.env        # Environment variables (gitignored)
└── README.md
```
