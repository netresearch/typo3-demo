#!/usr/bin/env bash
set -euo pipefail

# Run this once after server provisioning
# Usage: ssh deploy@<server> 'bash -s' < deploy/hetzner-setup.sh

REPO="https://github.com/netresearch/typo3-demo.git"
DEPLOY_DIR="/opt/typo3-demo"

echo "=== Setting up repository ==="
if [ -d "$DEPLOY_DIR/.git" ]; then
    echo "Repository already exists, pulling latest..."
    cd "$DEPLOY_DIR"
    git pull --ff-only
else
    git clone "$REPO" "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
fi
git lfs pull

echo "=== Creating .env ==="
if [ -f .env ]; then
    echo ".env already exists, skipping."
else
    cp .env.example .env
    echo ""
    echo "IMPORTANT: Edit /opt/typo3-demo/.env with production values before running 'make up'"
    echo "Required: TYPO3_DOMAIN, MARIADB_ROOT_PASSWORD, MARIADB_PASSWORD"
fi
