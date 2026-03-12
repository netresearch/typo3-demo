#!/usr/bin/env bash
set -euo pipefail

# Provision a fresh Hetzner CX23 (Ubuntu 24.04) for the TYPO3 demo.
# Run once as root after server creation.
#
# Usage:
#   scp deploy/hetzner-setup.sh root@<server-ip>:/tmp/
#   ssh root@<server-ip> bash /tmp/hetzner-setup.sh <ssh-public-key>

REPO="https://github.com/netresearch/typo3-demo.git"
DEPLOY_DIR="/opt/typo3-demo"

SSH_PUBKEY="${1:-}"
if [ -z "$SSH_PUBKEY" ]; then
    echo "Usage: bash hetzner-setup.sh <ssh-public-key>"
    echo "  The public key will be added to the deploy user's authorized_keys."
    exit 1
fi

echo "=== Installing packages ==="
apt-get update -qq
apt-get install -y -qq docker.io docker-compose-plugin git git-lfs make ufw fail2ban

echo "=== Enabling Docker ==="
systemctl enable --now docker

echo "=== Configuring firewall ==="
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 443/udp   # QUIC/HTTP3
ufw --force enable

echo "=== Setting up deploy user ==="
if ! id deploy &>/dev/null; then
    useradd -m -s /bin/bash -G docker deploy
    echo "Created 'deploy' user"
else
    usermod -aG docker deploy
    echo "'deploy' user already exists, ensured docker group"
fi

DEPLOY_SSH_DIR="/home/deploy/.ssh"
mkdir -p "$DEPLOY_SSH_DIR"
echo "$SSH_PUBKEY" > "$DEPLOY_SSH_DIR/authorized_keys"
chmod 700 "$DEPLOY_SSH_DIR"
chmod 600 "$DEPLOY_SSH_DIR/authorized_keys"
chown -R deploy:deploy "$DEPLOY_SSH_DIR"

echo "=== Installing Git LFS ==="
git lfs install --system

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
echo "Server IP: $SERVER_IP"
echo ""
echo "Next steps:"
echo "  1. Set GitHub secrets HETZNER_SSH_HOST and HETZNER_SSH_USER:"
echo "     gh secret set HETZNER_SSH_HOST -b '$SERVER_IP'"
echo "     gh secret set HETZNER_SSH_USER -b 'deploy'"
echo ""
echo "  2. Run 'Deploy (Fresh Install)' workflow from GitHub Actions"
echo ""
