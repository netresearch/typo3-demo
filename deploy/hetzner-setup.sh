#!/usr/bin/env bash
set -euo pipefail

# Provision a fresh Hetzner CX23 (Debian 13 "trixie") for the TYPO3 demo.
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
apt-get install -y -qq ca-certificates curl gnupg

echo "=== Adding Docker repository ==="
install -m 0755 -d /etc/apt/keyrings
curl -fsSL --proto '=https' --proto-redir '=https' https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin git make ufw fail2ban

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

echo "=== Hardening SSH ==="
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl reload sshd

echo "=== Setting the time zone ==="
# Automatic-Reboot-Time below is read in host-local time, and the Hetzner
# image runs in UTC. Europe/Berlin keeps the reboot at 03:00 local across DST.
timedatectl set-timezone Europe/Berlin

echo "=== Enabling automatic security updates ==="
# Debian's default origins include the debian-security archive, and its
# 20auto-upgrades enables the daily run. A new kernel is only used after a
# reboot, so unattended-upgrades reboots the host when an upgrade wrote
# /var/run/reboot-required. The containers come back through their
# restart policy.
apt-get install -y -qq unattended-upgrades
cat > /etc/apt/apt.conf.d/51auto-upgrades <<'EOF'
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-WithUsers "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
EOF
dpkg-reconfigure -f noninteractive unattended-upgrades

echo "=== Cloning repository ==="
if [ -d "$DEPLOY_DIR/.git" ]; then
    echo "Repository already exists, pulling latest..."
    cd "$DEPLOY_DIR"
    git pull --ff-only
else
    git clone "$REPO" "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
fi
chown -R deploy:deploy "$DEPLOY_DIR"

SERVER_IP=$(curl -s4 --proto '=https' https://ifconfig.me || echo '<this-server-ip>')

echo ""
echo "=== Setup complete ==="
echo ""
echo "Server IP: $SERVER_IP"
echo ""
echo "Next steps:"
echo "  1. Set the GitHub secret HETZNER_SSH_HOST and the variable HETZNER_SSH_USER:"
echo "     gh secret set HETZNER_SSH_HOST -b '$SERVER_IP'"
echo "     gh variable set HETZNER_SSH_USER -b 'deploy'"
echo ""
echo "  2. Run 'Deploy (Fresh Install)' workflow from GitHub Actions"
echo ""
