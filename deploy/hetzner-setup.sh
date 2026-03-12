#!/usr/bin/env bash
set -euo pipefail

# Run this once after server provisioning
# Usage: ssh deploy@<server> 'bash -s' < deploy/hetzner-setup.sh

REPO="https://github.com/netresearch/typo3-demo.git"
DEPLOY_DIR="/opt/typo3-demo"

echo "=== Cloning repository ==="
git clone "$REPO" "$DEPLOY_DIR"
cd "$DEPLOY_DIR"
git lfs pull

echo "=== Creating .env ==="
cp .env.example .env
echo ""
echo "IMPORTANT: Edit /opt/typo3-demo/.env with production values before running 'make up'"
echo "Required: TYPO3_DOMAIN, TYPO3_SETUP_ADMIN_PASSWORD, TYPO3_BACKEND_PATH, MARIADB_ROOT_PASSWORD"
