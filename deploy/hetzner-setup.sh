#!/usr/bin/env bash
set -euo pipefail

# Run this once after server provisioning (cloud-init must have completed)
#
# Usage:
#   scp deploy/hetzner-setup.sh root@<server-ip>:/tmp/
#   ssh root@<server-ip> bash /tmp/hetzner-setup.sh <ssh-public-key>
#
# Example:
#   scp deploy/hetzner-setup.sh root@1.2.3.4:/tmp/
#   ssh root@1.2.3.4 bash /tmp/hetzner-setup.sh "ssh-ed25519 AAAA... deploy@github"

REPO="https://github.com/netresearch/typo3-demo.git"
DEPLOY_DIR="/opt/typo3-demo"

SSH_PUBKEY="${1:-}"
if [ -z "$SSH_PUBKEY" ]; then
    echo "Usage: bash hetzner-setup.sh <ssh-public-key>"
    echo "  The public key will be added to the deploy user's authorized_keys."
    exit 1
fi

echo "=== Verifying prerequisites ==="
for cmd in docker git git-lfs make; do
    command -v "$cmd" >/dev/null || { echo "ERROR: $cmd not found (cloud-init may still be running)"; exit 1; }
done

echo "=== Setting up deploy user ==="
if ! id deploy &>/dev/null; then
    useradd -m -s /bin/bash -G docker deploy
    echo "Created 'deploy' user"
else
    echo "'deploy' user already exists"
fi

echo "=== Setting up SSH key for deploy user ==="
DEPLOY_SSH_DIR="/home/deploy/.ssh"
mkdir -p "$DEPLOY_SSH_DIR"
echo "$SSH_PUBKEY" > "$DEPLOY_SSH_DIR/authorized_keys"
chmod 700 "$DEPLOY_SSH_DIR"
chmod 600 "$DEPLOY_SSH_DIR/authorized_keys"
chown -R deploy:deploy "$DEPLOY_SSH_DIR"
echo "SSH key installed for deploy user."

echo "=== Cloning repository ==="
if [ -d "$DEPLOY_DIR/.git" ]; then
    echo "Repository already exists, pulling latest..."
    cd "$DEPLOY_DIR"
    git pull --ff-only
else
    git clone "$REPO" "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
fi
git lfs pull
chown -R deploy:deploy "$DEPLOY_DIR"

SERVER_IP=$(curl -s4 ifconfig.me || echo '<this-server-ip>')

echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Add these GitHub repository secrets (Settings → Secrets → Actions):"
echo "     HETZNER_SSH_HOST      = $SERVER_IP"
echo "     HETZNER_SSH_USER      = deploy"
echo "     HETZNER_SSH_KEY       = <private key matching the public key above>"
echo "     TYPO3_DOMAIN          = typo3-demo.netresearch.de"
echo "     MARIADB_ROOT_PASSWORD = <generate a strong password>"
echo "     MARIADB_PASSWORD      = <generate a strong password>"
echo "     TYPO3_ENCRYPTION_KEY  = $(openssl rand -hex 48)"
echo ""
echo "  2. Create the 'production' environment in GitHub (Settings → Environments)"
echo ""
echo "  3. Run 'Deploy (Fresh Install)' workflow from GitHub Actions"
echo ""
