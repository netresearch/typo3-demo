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

# Configure nr_ai_search (RAG frontend Search + Chat) and lochmueller/index.
# Same managed-block approach as nr_mcp_agent above: a single marked block is
# (re)written each boot; any other additional.php content is preserved.
# - nr_ai_search points at the seeded nr_llm embeddings/chat configurations and
#   the seeded non-admin technical be_user (uid 990, data/seed-extensions.sql).
#   embeddingDimensions (1536) MUST equal the seeded embedding model's real
#   output width.
# - index (lochmueller/index) is told to index synchronously in Development
#   context, so the single `index:queue` further below emits IndexPageEvent
#   inline instead of persisting to a separate 'index' transport that would
#   otherwise need its own long-running consumer.
if [ -f config/system/settings.php ]; then
    php -r '
        $f = "config/system/additional.php";
        $begin = "// >>> nr_ai_search (managed by entrypoint, do not edit this block)";
        $end   = "// <<< nr_ai_search";
        $block = $begin . "\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"nr_ai_search\"][\"embeddingConfiguration\"] = \"nr_ai_search.embeddings\";\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"nr_ai_search\"][\"chatConfiguration\"] = \"nr_ai_search.chat\";\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"nr_ai_search\"][\"embeddingDimensions\"] = \"1536\";\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"nr_ai_search\"][\"technicalBeUserUid\"] = \"990\";\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"nr_ai_search\"][\"rateLimitPerMinute\"] = \"10\";\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"nr_ai_search\"][\"hybridSearchEnabled\"] = \"0\";\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"index\"][\"defaultTransportInDevelopmentContext\"] = \"1\";\n"
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
        echo "additional.php: nr_ai_search configured (technicalBeUserUid=990, dims=1536), index dev-sync on." . PHP_EOL;
    ' || echo "WARNING: failed to write nr_ai_search additional.php block" >&2
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

# ---------------------------------------------------------------------------
# nr_ai_search content vectorization (best-effort, never blocks boot).
# ---------------------------------------------------------------------------
# lochmueller/index's configuration table (tx_index_domain_model_configuration)
# is created by extension:setup above — so its seed row is applied HERE, not in
# data/seed-extensions.sql (which is imported before setup, when the table does
# not yet exist). Then one synchronous index run (Development context, see the
# index dev-sync flag in additional.php above) emits IndexPageEvent per page;
# nr_ai_search turns each into an embedding job on its own 'nr_ai_search'
# Messenger queue, drained by the bounded consume below.
#
# Gate on whether any content is actually EMBEDDED (tx_nraisearch_chunk), NOT on
# vektor-store files: centamiv/vektor writes empty index files even when zero
# vectors were added, so a file-existence gate latches "done" after a failed first
# run and never retries (observed on the live instance: 0 tracked chunks, an empty
# store dir with index files, and index:queue never re-run). Gating on the
# tracked-chunk count self-heals — once the embedding path works end to end (real
# OpenAI key in Vault, resolvable by the worker's technical BE user 990), the next
# boot fills the queue and the worker populates the store. `make reset` also works.
CHUNK_COUNT="$(MYSQL_PWD="${MARIADB_PASSWORD:-typo3}" mariadb -h"${MARIADB_HOST:-db}" -u"${MARIADB_USER:-typo3}" "${MARIADB_DATABASE:-typo3}" -N -e "SELECT COUNT(*) FROM tx_nraisearch_chunk" 2>/dev/null || echo 0)"
if [ -f config/system/settings.php ] && [ "${CHUNK_COUNT:-0}" = "0" ]; then
    echo "nr_ai_search: no embedded chunks yet (tx_nraisearch_chunk empty) — seeding index config and (re)filling the index queue..."
    MYSQL_PWD="${MARIADB_PASSWORD:-typo3}" mariadb -h"${MARIADB_HOST:-db}" -u"${MARIADB_USER:-typo3}" "${MARIADB_DATABASE:-typo3}" 2>/dev/null <<'SQL' || echo "WARNING: index configuration seed failed" >&2
INSERT INTO tx_index_domain_model_configuration
    (pid, tstamp, crdate, deleted, hidden, title, technology, content_indexing,
     skip_no_search_pages, levels, languages, configuration, partial_indexing,
     file_mounts, file_types, content_processors)
SELECT 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0, 0, 'Demo content (nr_ai_search)',
     'database', 1, 0, 30, '0', '{}', '', '', '', ''
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM tx_index_domain_model_configuration WHERE pid = 1 AND deleted = 0
);
SQL

    # Drop any empty/partial vektor store so a stale (zero-vector) index structure
    # from a prior failed run does not linger alongside the fresh embeddings.
    rm -rf var/nr_ai_search/vektor-store 2>/dev/null || true

    echo "Filling index queue (synchronous) — emits page-index events for nr_ai_search..."
    TYPO3_SITE_BASE="https://${TYPO3_DOMAIN:-localhost}/" \
        vendor/bin/typo3 index:queue 2>&1 \
        || echo "WARNING: index:queue failed — content not vectorized until re-run" >&2

    mkdir -p var/nr_ai_search
    chown -R www-data:www-data var/nr_ai_search 2>/dev/null || true
fi

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
