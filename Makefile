include homelab.env

export ISO_FILENAME := $(shell basename $(ISO_URL))
export PROXMOX_URL := https://$(PROXMOX_HOST):8006/api2/json
export PKR_VAR_vm_password_hash := $(shell openssl passwd -6 "$(VM_PASSWORD)")

.PHONY: all bootstrap build deploy

all: bootstrap build deploy

bootstrap:
	@echo "--- Step 1: Bootstrapping Proxmox ---"
	ansible-playbook -i "$(PROXMOX_HOST)," -u root ansible/bootstrap.yml \
		-e "iso_url=$(ISO_URL)" \
		-e "iso_filename=$(ISO_FILENAME)" \
		-e "iso_checksum=$(ISO_CHECKSUM)"

build:
	@echo "--- Step 2: Building Golden Image ---"
	cd packer && packer init . && packer build \
		-var "proxmox_url=$(PROXMOX_URL)" \
		-var "proxmox_username=$(PROXMOX_USERNAME)" \
		-var "proxmox_password=$(PROXMOX_PASSWORD)" \
		-var "node_name=$(NODE_NAME)" \
		-var "template_vm_id=$(TEMPLATE_VM_ID)" \
		-var "ssh_public_key_file=$(SSH_PUBLIC_KEY_FILE)" \
		-var "ssh_private_key_file=$(SSH_PRIVATE_KEY_FILE)" \
		-var "iso_checksum=$(ISO_CHECKSUM)" \
		-var "iso_filename=$(ISO_FILENAME)" \
		-var "nfs_server=$(PROXMOX_HOST)" \
		.

deploy:
	@echo "--- Step 3: Deploying Infrastructure ---"
	cd terraform && terraform init && terraform apply -auto-approve \
		-var "proxmox_url=$(PROXMOX_URL)" \
		-var "proxmox_username=$(PROXMOX_USERNAME)" \
		-var "proxmox_password=$(PROXMOX_PASSWORD)" \
		-var "node_name=$(NODE_NAME)" \
		-var "template_vm_id=$(TEMPLATE_VM_ID)" \
		-var "ssh_public_key_file=$(SSH_PUBLIC_KEY_FILE)" \
