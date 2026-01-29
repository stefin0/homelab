#!/bin/bash
set -eou pipefail

CONFIG_FILE="homelab.config"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file '$CONFIG_FILE' not found."
    echo "Please copy homelab.config.example to homelab.config and edit it."
    exit 1
fi
source "$CONFIG_FILE"

if [ "${VM_PASSWORD:-}" != "" ]; then
    echo "Generating password hash from homelab.config..."
    export PKR_VAR_vm_password_hash=$(openssl passwd -6 "$VM_PASSWORD")
else
    echo "ERROR: VM_PASSWORD not found in $CONFIG_FILE"
    exit 1
fi

if [ -f "$SSH_KEY_PATH" ]; then
    SSH_KEY_CONTENT=$(cat "$SSH_KEY_PATH")
else
    echo "ERROR: SSH Key not found at $SSH_KEY_PATH"
    exit 1
fi

# --- Helper Functions ---
error() {
    echo -e "ERROR: $*" >&2
    exit 1

}
usage() {
    echo "Usage: $0 {bootstrap|build|deploy|all}"
    echo "  bootstrap   Run configuration to setup Proxmox and rotate keys"
    echo "  build       Build the Golden Image"
    echo "  deploy      Provision the infrastructure"
    echo "  all         Run the entire pipeline (default)"
    exit 1
}

SECRETS_FILE=".env"
load_secrets() {
    if [ -f "$SECRETS_FILE" ]; then
        source "$SECRETS_FILE"
        echo "Secrets loaded from $SECRETS_FILE."
    else
        echo "WARNING: Secrets file ($SECRETS_FILE) not found. This is normal if you haven't run bootstrap yet."
    fi
}

check_deps() {
    command -v ansible-playbook >/dev/null 2>&1 || error "Ansible is missing"
    command -v packer >/dev/null 2>&1 || error "Packer is missing."
    command -v terraform >/dev/null 2>&1 || error "Terraform is missing"
    command -v openssl >/dev/null 2>&1 || error "openssl is missing"
}

# --- 1. Bootstrap & Secrets ---
run_bootstrap() {
    echo "Step 1: Bootstrapping Proxmox & Rotating Secrets..."

    ISO_FILENAME=$(basename "$ISO_URL")
    echo "Using ISO: $ISO_FILENAME derived from URL."

    ansible-playbook -i "$PROXMOX_HOST," -u root configuration/bootstrap.yml \
        -e "iso_url=$ISO_URL" \
        -e "iso_checksum=$ISO_CHECKSUM" \
        -e "iso_filename=$ISO_FILENAME"

    # Force reload secrets immediately after bootstrap generated them
    if [ -f "$SECRETS_FILE" ]; then
        source "$SECRETS_FILE"
        echo "New secrets successfully loaded."
    else
        error "Bootstrap finished, but $SECRETS_FILE was not found. Check Ansible logs."
    fi
}

# --- 2. Build Image ---
run_build() {
    if [ "${PROXMOX_API_TOKEN_ID:-}" = "" ]; then
        error "Proxmox API Token not loaded. Run 'bootstrap' first."
    fi

    echo "Step 2: Building Golden Image..."
    cd images

    ISO_FILENAME=$(basename "$ISO_URL")

    export PKR_VAR_proxmox_api_token_id="$PROXMOX_API_TOKEN_ID"
    export PKR_VAR_proxmox_api_token_secret="$PROXMOX_API_TOKEN_SECRET"
    export PKR_VAR_proxmox_api_url="$PROXMOX_URL"
    export PKR_VAR_vm_id="$TEMPLATE_ID"
    export PKR_VAR_ssh_public_key="$SSH_KEY_CONTENT"
    export PKR_VAR_iso_url="$ISO_URL"
    export PKR_VAR_iso_checksum="$ISO_CHECKSUM"
    export PKR_VAR_iso_filename="$ISO_FILENAME"

    packer init .
    packer build .
    cd ..
}

# --- 3. Deploy Infrastructure ---
run_deploy() {
    if [ "${PROXMOX_API_TOKEN_ID:-}" = "" ]; then
        error "Proxmox API Token not loaded. Run 'bootstrap' first."
    fi

    echo "Step 3: Terraform Apply..."

    cd infrastructure

    export TF_VAR_proxmox_api_token_id="$PROXMOX_API_TOKEN_ID"
    export TF_VAR_proxmox_api_token_secret="$PROXMOX_API_TOKEN_SECRET"
    export TF_VAR_proxmox_api_url="$PROXMOX_URL"
    export TF_VAR_target_node="$TARGET_NODE"
    export TF_VAR_template_vm_id="$TEMPLATE_ID"
    export TF_VAR_ssh_public_key="$SSH_KEY_CONTENT"

    terraform init
    terraform apply -auto-approve
    cd ..
}

# --- Main Execution Logic ---
check_deps
load_secrets

MODE="${1:-all}"

case "$MODE" in
bootstrap)
    run_bootstrap
    ;;
build)
    run_build
    ;;
deploy)
    run_deploy
    ;;
all)
    run_bootstrap
    run_build
    run_deploy
    ;;
*)
    usage
    ;;
esac

echo "Operation '$MODE' completed successfully."
