#!/bin/sh
set -eu

echo "Waiting for database (host=${MARIADB_HOST:-db}, db=${MARIADB_DATABASE:-typo3})..."
n=0
until MYSQL_PWD="${MARIADB_PASSWORD:-typo3}" mariadb -h"${MARIADB_HOST:-db}" -u"${MARIADB_USER:-typo3}" "${MARIADB_DATABASE:-typo3}" -e 'SELECT 1' >/dev/null 2>&1; do
    n=$((n + 1))
    if [ "$n" -ge 60 ]; then
        echo "ERROR: Database not ready after 60s, aborting." >&2
        MYSQL_PWD="${MARIADB_PASSWORD:-typo3}" mariadb -h"${MARIADB_HOST:-db}" -u"${MARIADB_USER:-typo3}" "${MARIADB_DATABASE:-typo3}" -e 'SELECT 1' 2>&1 || true
        exit 1
    fi
    sleep 1
done
echo "Database ready."

# Verify seed data exists (DB init should be complete before web starts via depends_on)
TABLE_COUNT=$(MYSQL_PWD="${MARIADB_PASSWORD:-typo3}" mariadb -h"${MARIADB_HOST:-db}" -u"${MARIADB_USER:-typo3}" "${MARIADB_DATABASE:-typo3}" -N -e 'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE()' 2>/dev/null || echo "0")
echo "Database has $TABLE_COUNT tables."

mkdir -p var/log var/cache var/lock var/charset var/labels \
    public/fileadmin public/typo3temp/assets/_processed_ config/system
chown -R www-data:www-data var public/fileadmin public/typo3temp

if [ -d /seed/fileadmin ] && [ -z "$(ls -A public/fileadmin 2>/dev/null)" ]; then
    echo "Seeding fileadmin from image..."
    cp -a /seed/fileadmin/. public/fileadmin/
    chown -R www-data:www-data public/fileadmin
    echo "Fileadmin seeded."
fi

if [ ! -f config/system/settings.php ]; then
    ENCRYPTION_KEY="${TYPO3_ENCRYPTION_KEY:-$(openssl rand -hex 48)}"

    # Derive trustedHostsPattern from TYPO3_DOMAIN
    DOMAIN="${TYPO3_DOMAIN:-localhost}"
    if [ "$DOMAIN" = "localhost" ]; then
        TRUSTED_PATTERN='^(localhost|127\\.0\\.0\\.1)$'
    else
        # Allow configured domain + localhost/127.0.0.1 for healthchecks
        ESCAPED_DOMAIN="$(echo "$DOMAIN" | sed 's/\./\\\\./g')"
        TRUSTED_PATTERN="^(${ESCAPED_DOMAIN}|localhost|127\\\\.0\\\\.0\\\\.1)$"
    fi

    echo "First boot: generating settings.php..."
    # Use quoted heredoc to prevent shell expansion, then substitute with sed
    cat > config/system/settings.php <<'EOPHP'
<?php
return [
    'DB' => [
        'Connections' => [
            'Default' => [
                'charset' => 'utf8mb4',
                'driver' => 'mysqli',
                'host' => '%%MARIADB_HOST%%',
                'port' => 3306,
                'dbname' => '%%MARIADB_DATABASE%%',
                'user' => '%%MARIADB_USER%%',
                'password' => '%%MARIADB_PASSWORD%%',
            ],
        ],
    ],
    'SYS' => [
        'encryptionKey' => '%%ENCRYPTION_KEY%%',
        'trustedHostsPattern' => '%%TRUSTED_PATTERN%%',
        'reverseProxyIP' => '*',
        'reverseProxyHeaderMultiValue' => 'first',
        'reverseProxySSL' => '*',
        'sitename' => 'Netresearch TYPO3 Demo',
        'caching' => [
            'cacheConfigurations' => [
                'hash' => [
                    'backend' => \TYPO3\CMS\Core\Cache\Backend\RedisBackend::class,
                    'options' => [
                        'hostname' => 'valkey',
                        'port' => 6379,
                        'database' => 0,
                    ],
                ],
                'pages' => [
                    'backend' => \TYPO3\CMS\Core\Cache\Backend\RedisBackend::class,
                    'options' => [
                        'hostname' => 'valkey',
                        'port' => 6379,
                        'database' => 1,
                    ],
                ],
                'rootline' => [
                    'backend' => \TYPO3\CMS\Core\Cache\Backend\RedisBackend::class,
                    'options' => [
                        'hostname' => 'valkey',
                        'port' => 6379,
                        'database' => 2,
                    ],
                ],
            ],
        ],
    ],
    'GFX' => [
        'processor' => 'ImageMagick',
        'processor_path' => '/usr/bin/',
        'processor_effects' => true,
    ],
    'BE' => [
        'debug' => false,
        'passwordHashing' => [
            'className' => \TYPO3\CMS\Core\Crypto\PasswordHashing\Argon2idPasswordHash::class,
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
        'transport' => 'null',
    ],
];
EOPHP

    # Safely substitute placeholders — handles special chars in passwords
    # First escape single quotes for PHP, then escape sed metacharacters
    escape_for_php() { printf '%s' "$1" | sed "s/'/\\\\'/g"; }
    escape_sed() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/[&|]/\\&/g'; }
    sed -i "s|%%MARIADB_HOST%%|$(escape_sed "$(escape_for_php "${MARIADB_HOST:-db}")")|g" config/system/settings.php
    sed -i "s|%%MARIADB_DATABASE%%|$(escape_sed "$(escape_for_php "${MARIADB_DATABASE:-typo3}")")|g" config/system/settings.php
    sed -i "s|%%MARIADB_USER%%|$(escape_sed "$(escape_for_php "${MARIADB_USER:-typo3}")")|g" config/system/settings.php
    sed -i "s|%%MARIADB_PASSWORD%%|$(escape_sed "$(escape_for_php "${MARIADB_PASSWORD:-typo3}")")|g" config/system/settings.php
    sed -i "s|%%ENCRYPTION_KEY%%|$(escape_sed "$ENCRYPTION_KEY")|g" config/system/settings.php
    sed -i "s|%%TRUSTED_PATTERN%%|$(escape_sed "$TRUSTED_PATTERN")|g" config/system/settings.php
    echo "settings.php generated."

    echo "Cleaning up legacy sys_template records (v11 TypoScript, replaced by Site Sets)..."
    MYSQL_PWD="${MARIADB_PASSWORD:-typo3}" mariadb -h"${MARIADB_HOST:-db}" -u"${MARIADB_USER:-typo3}" "${MARIADB_DATABASE:-typo3}" \
        -e "DELETE FROM sys_template;" 2>/dev/null || true

    echo "Importing extension demo pages..."
    if [ -f /var/www/data/seed-extensions.sql ]; then
        MYSQL_PWD="${MARIADB_PASSWORD:-typo3}" mariadb -h"${MARIADB_HOST:-db}" -u"${MARIADB_USER:-typo3}" "${MARIADB_DATABASE:-typo3}" \
            < /var/www/data/seed-extensions.sql 2>/dev/null || echo "WARNING: seed-extensions.sql import failed" >&2
    fi
fi

echo "Running TYPO3 setup..."
vendor/bin/typo3 extension:setup 2>&1 || echo "WARNING: extension:setup failed" >&2

# Apply extension DB schemas that TCA auto-schema cannot derive.
# extension:setup handles TCA-derived columns (int, varchar, text) but not
# varbinary, blob, char, or custom indexes from ext_tables.sql.
echo "Applying extension database schemas..."
if [ -f /var/www/data/seed-schema.sql ]; then
    MYSQL_PWD="${MARIADB_PASSWORD:-typo3}" mariadb -h"${MARIADB_HOST:-db}" -u"${MARIADB_USER:-typo3}" "${MARIADB_DATABASE:-typo3}" \
        < /var/www/data/seed-schema.sql 2>/dev/null || echo "WARNING: seed-schema.sql import failed" >&2
fi
vendor/bin/typo3 cache:flush 2>&1 || echo "WARNING: cache:flush failed" >&2
vendor/bin/typo3 cache:warmup 2>&1 || echo "WARNING: cache:warmup failed" >&2

# Workaround: Bootstrap Package 16.0.0 has a bug in GoogleFontService.php where
# $response->getBody()->getContents() is called twice — the second call returns empty
# because the stream was already consumed, producing a 0-byte webfont.css.
# Replace the duplicate call with a stream rewind so the second read works.
GFONT_SVC="vendor/bk2k/bootstrap-package/Classes/Service/GoogleFontService.php"
if [ -f "$GFONT_SVC" ] && [ "$(grep -c '\$content = \$response->getBody()->getContents()' "$GFONT_SVC")" = "2" ]; then
    echo "Patching Bootstrap Package GoogleFontService (duplicate getContents bug)..."
    php -r "
        \$f = file_get_contents('$GFONT_SVC');
        \$needle = '\$content = \$response->getBody()->getContents();';
        \$pos = strpos(\$f, \$needle);
        if (\$pos !== false) {
            \$pos2 = strpos(\$f, \$needle, \$pos + strlen(\$needle));
            if (\$pos2 !== false) {
                \$f = substr(\$f, 0, \$pos2) . '\$response->getBody()->rewind(); \$content = \$response->getBody()->getContents();' . substr(\$f, \$pos2 + strlen(\$needle));
                file_put_contents('$GFONT_SVC', \$f);
            }
        }
    "
fi

chown -R www-data:www-data var config/system public/typo3temp
echo "Entrypoint complete, starting services..."
exec "$@"
