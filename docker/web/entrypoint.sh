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

# Ensure installToolPassword is set (required by TYPO3; may be absent in older settings.php)
if [ -f config/system/settings.php ]; then
    TYPO3_INSTALL_TOOL_PASSWORD_PLAIN="${TYPO3_INSTALL_TOOL_PASSWORD:-joh316}" php -r '
        $f = "config/system/settings.php";
        $cfg = include $f;
        if (!is_array($cfg) || !empty($cfg["BE"]["installToolPassword"])) { exit(0); }
        $pw = getenv("TYPO3_INSTALL_TOOL_PASSWORD_PLAIN") ?: "joh316";
        $cfg["BE"]["installToolPassword"] = password_hash($pw, PASSWORD_ARGON2ID);
        file_put_contents($f, "<?php\nreturn " . var_export($cfg, true) . ";\n");
        echo "installToolPassword added to settings.php." . PHP_EOL;
    '
fi

# Enable the MCP-backed AI Chat (nr_mcp_agent) and point it at the seeded nr-llm
# Task (uid 1). config/system is a Docker volume that overlays any repo-provided
# file, so this is (re)written on every boot. It is idempotent and merge-safe:
# only a marked block is managed, any other additional.php content is preserved.
# TYPO3 loads config/system/additional.php automatically after settings.php.
if [ -f config/system/settings.php ]; then
    php -r '
        $f = "config/system/additional.php";
        $begin = "// >>> nr_mcp_agent (managed by entrypoint, do not edit this block)";
        $end   = "// <<< nr_mcp_agent";
        $block = $begin . "\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"nr_mcp_agent\"][\"enableMcp\"] = \"1\";\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"nr_mcp_agent\"][\"llmTaskUid\"] = \"1\";\n"
            . $end;
        $existing = is_file($f) ? (string) file_get_contents($f) : "";
        if (strpos($existing, "<?php") === false) {
            $existing = "<?php\n" . ($existing === "" ? "" : $existing . "\n");
        }
        $b = strpos($existing, $begin);
        if ($b !== false) {
            $e = strpos($existing, $end, $b);
            $existing = $e !== false
                ? substr($existing, 0, $b) . substr($existing, $e + strlen($end))
                : substr($existing, 0, $b);
        }
        $existing = rtrim($existing, "\n") . "\n\n" . $block . "\n";
        file_put_contents($f, $existing);
        echo "additional.php: MCP enabled, nr_mcp_agent.llmTaskUid=1." . PHP_EOL;
    ' || echo "WARNING: failed to write additional.php" >&2
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

# EXT:solr connection probe + indexing (disposable spike).
# EXT:solr v14 ships NO console commands of its own — indexing is normally driven
# by the backend "Index Queue" module plus the Index Queue Worker scheduler task.
# The site package provides an in-process equivalent (demo:solr:index) so the demo
# indexes end-to-end on boot. This block first verifies the Solr server is
# reachable (a misconfigured connection is then visible in the logs) and, when it
# is, runs the indexing command. It is deliberately tolerant: an unreachable Solr
# or a failed index run must never break web boot (mirrors `|| echo WARNING`).
SOLR_HOST="${SOLR_HOST:-solr}"
SOLR_PORT="${SOLR_PORT:-8983}"
echo "Probing Apache Solr at ${SOLR_HOST}:${SOLR_PORT}..."
solr_ok=0
n=0
while [ "$n" -lt 15 ]; do
    # NOSONAR (shell:S5332): Solr is an internal-only container on the compose
    # network with no TLS; http:// is the only scheme it serves.
    if wget -q -O /dev/null "http://${SOLR_HOST}:${SOLR_PORT}/solr/admin/cores?action=STATUS" 2>/dev/null; then # NOSONAR
        solr_ok=1
        break
    fi
    n=$((n + 1))
    sleep 2
done
if [ "$solr_ok" = "1" ]; then
    echo "Solr reachable; indexing demo content into Solr..."
    # The in-process front-end indexing sub-request needs a site base with a real
    # host: otherwise EXT:solr throws SolrIndexRuntimeException 1741200001 and the
    # stored result URLs are hostless. TYPO3_DOMAIN is the deployed domain on live
    # and localhost locally, so result links point at the right host either way.
    TYPO3_SITE_BASE="https://${TYPO3_DOMAIN}/" vendor/bin/typo3 demo:solr:index 2>&1 \
        || echo "WARNING: demo:solr:index failed" >&2
else
    echo "WARNING: Solr not reachable at ${SOLR_HOST}:${SOLR_PORT} — search unavailable, continuing boot." >&2
fi

chown -R www-data:www-data var config/system public/typo3temp
echo "Entrypoint complete, starting services..."
exec "$@"
