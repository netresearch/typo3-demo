#!/bin/sh
set -e
echo "Waiting for database..."
until mariadb -h"${MARIADB_HOST:-db}" -u"${MARIADB_USER:-typo3}" -p"${MARIADB_PASSWORD:-typo3}" -e "SELECT 1" >/dev/null 2>&1; do
    sleep 1
done
echo "Database ready."
mkdir -p var/log var/cache var/lock var/charset var/labels
chown -R www-data:www-data var public/fileadmin 2>/dev/null || true
if [ ! -f config/system/settings.php ]; then
    echo "First boot: running TYPO3 setup..."
    vendor/bin/typo3 setup \
        --driver=mysqli \
        --host="${MARIADB_HOST:-db}" \
        --port=3306 \
        --dbname="${MARIADB_DATABASE:-typo3}" \
        --username="${MARIADB_USER:-typo3}" \
        --password="${MARIADB_PASSWORD:-typo3}" \
        --admin-username="${TYPO3_SETUP_ADMIN_USERNAME:-admin}" \
        --admin-password="${TYPO3_SETUP_ADMIN_PASSWORD:-changeme!2026}" \
        --admin-email="demo@netresearch.de" \
        --project-name="Netresearch TYPO3 Demo" \
        --server-type=other \
        --no-interaction
fi
vendor/bin/typo3 extension:setup || true
vendor/bin/typo3 cache:flush || true
vendor/bin/typo3 cache:warmup || true
exec "$@"
