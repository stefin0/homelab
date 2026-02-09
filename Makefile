include homelab.env

export ISO_FILENAME := $(shell basename $(ISO_URL))

ifneq ($(VM_PASSWORD),)
	export PKR_VAR_vm_password_hash := $(shell openssl passwd -6 "$(VM_PASSWORD)")
endif

export

.PHONY: all bootstrap build deploy

all: bootstrap build deploy

bootstrap:
	@echo "--- Step 1: Bootstrapping Proxmox ---"
	ansible-playbook -i "$(PROXMOX_HOST)," -u root configuration/bootstrap.yml \
		-e "iso_url=$(ISO_URL)" \
		-e "iso_filename=$(ISO_FILENAME)" \
		-e "iso_checksum=$(ISO_CHECKSUM)"

build:
	@echo "--- Step 2: Building Golden Image ---"
	cd images && packer init . && packer build \
		-var "proxmox_url=$(PROXMOX_URL)" \
		-var "proxmox_username=$(PROXMOX_USERNAME)" \
		-var "proxmox_password=$(PROXMOX_PASSWORD)" \
		-var "node_name=$(NODE_NAME)" \
		-var "template_vm_id=$(TEMPLATE_VM_ID)" \
		-var "ssh_public_key_file=$(SSH_PUBLIC_KEY_FILE)" \
		-var "ssh_private_key_file=$(SSH_PRIVATE_KEY_FILE)" \
		-var "iso_checksum=$(ISO_CHECKSUM)" \
		-var "iso_filename=$(ISO_FILENAME)" \
		.

deploy:
	@echo "--- Step 3: Deploying Infrastructure ---"
	cd infrastructure && terraform init && terraform apply -auto-approve \
		-var "proxmox_url=$(PROXMOX_URL)" \
		-var "proxmox_username=$(PROXMOX_USERNAME)" \
		-var "proxmox_password=$(PROXMOX_PASSWORD)" \
		-var "node_name=$(NODE_NAME)" \
		-var "template_vm_id=$(TEMPLATE_VM_ID)" \
		-var "ssh_public_key_file=$(SSH_PUBLIC_KEY_FILE)" \
