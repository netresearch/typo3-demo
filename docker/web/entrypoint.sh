#!/bin/sh
set -e
echo "Waiting for database..."
until mariadb -h"${MARIADB_HOST:-db}" -u"${MARIADB_USER:-typo3}" -p"${MARIADB_PASSWORD:-typo3}" -e "SELECT 1" >/dev/null 2>&1; do
    sleep 1
done
echo "Database ready."
mkdir -p var/log var/cache var/lock var/charset var/labels \
    public/fileadmin public/typo3temp/assets/_processed_ config/system
chown -R www-data:www-data var public/fileadmin public/typo3temp 2>/dev/null || true

if [ -d /seed/fileadmin ] && [ -z "$(ls -A public/fileadmin 2>/dev/null)" ]; then
    echo "Seeding fileadmin from image..."
    cp -a /seed/fileadmin/. public/fileadmin/
    chown -R www-data:www-data public/fileadmin
    echo "Fileadmin seeded."
fi

if [ ! -f config/system/settings.php ]; then
    ENCRYPTION_KEY=$(head -c 48 /dev/urandom | od -An -tx1 | tr -d " \n")
    echo "First boot: generating settings.php..."
    cat > config/system/settings.php <<EOF
<?php
return [
    'DB' => [
        'Connections' => [
            'Default' => [
                'charset' => 'utf8',
                'driver' => 'mysqli',
                'host' => '${MARIADB_HOST:-db}',
                'port' => 3306,
                'dbname' => '${MARIADB_DATABASE:-typo3}',
                'user' => '${MARIADB_USER:-typo3}',
                'password' => '${MARIADB_PASSWORD:-typo3}',
            ],
        ],
    ],
    'SYS' => [
        'encryptionKey' => '${ENCRYPTION_KEY}',
        'trustedHostsPattern' => '.*',
        'sitename' => 'Netresearch TYPO3 Demo',
    ],
    'BE' => [
        'debug' => false,
        'passwordHashing' => [
            'className' => 'TYPO3\\\\CMS\\\\Core\\\\Crypto\\\\PasswordHashing\\\\Argon2idPasswordHashing',
        ],
    ],
    'FE' => [
        'debug' => false,
        'disableNoCacheParameter' => true,
        'cacheHash' => [
            'enforceValidation' => true,
        ],
    ],
    'MAIL' => [
        'transport' => 'sendmail',
        'transport_sendmail_command' => '/usr/sbin/sendmail -t -i',
    ],
];
EOF
    echo "settings.php generated."

    echo "Cleaning up legacy sys_template records..."
    mariadb -h"${MARIADB_HOST:-db}" -u"${MARIADB_USER:-typo3}" -p"${MARIADB_PASSWORD:-typo3}" "${MARIADB_DATABASE:-typo3}" \
        -e "DELETE FROM sys_template;" 2>/dev/null || true
fi

vendor/bin/typo3 extension:setup || true
vendor/bin/typo3 cache:flush || true
vendor/bin/typo3 cache:warmup || true
chown -R www-data:www-data var config/system public/typo3temp 2>/dev/null || true
exec "$@"
