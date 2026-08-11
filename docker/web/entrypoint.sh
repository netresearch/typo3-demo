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
        // The marker text is load-bearing: the replacement below finds the old
        // block by searching for it. Renaming it would leave every existing
        // additional.php with an orphaned block nobody removes, so it keeps the
        // nr_ai_search name even though the block now also carries nr_vault.
        $begin = "// >>> nr_ai_search (managed by entrypoint, do not edit this block)";
        $end   = "// <<< nr_ai_search";
        $block = $begin . "\n"
            // The identity `vault:store --as-provisioner` acts as; seeded in
            // data/seed-extensions.sql with exactly two vault permissions.
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"nr_vault\"][\"provisioningBeUserUid\"] = \"991\";\n"
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
        echo "additional.php: nr_ai_search configured (technicalBeUserUid=990, dims=1536), nr_vault provisioning actor 991, index dev-sync on." . PHP_EOL;
    ' || echo "WARNING: failed to write nr_ai_search additional.php block" >&2
fi

# Configure ai_filemetadata (AI-generated alternative texts for FAL images).
#
# Like autotranslate, this extension reads a plain API key from its own
# extension configuration and knows nothing about nr-vault, so the vault route
# the LLM modules take is unavailable to it. It speaks the OpenAI API directly,
# which means the existing OPENAI_API_KEY secret covers it — no second secret.
#
# The key is only written when the variable is non-empty; an empty variable
# leaves whatever a previous boot stored, same rule as everywhere else here.
#
# imageResizing = 512 shrinks images before upload. That is a cost control, not
# a quality setting: full-resolution uploads are billed by the pixel and add
# nothing to a 50-word alt text.
# generateAltTextInFrontend = 0 keeps a missing alt text from triggering a
# synchronous API call while a visitor waits for the page.
if [ -f config/system/settings.php ]; then
    php -r '
        $f = "config/system/additional.php";
        $begin = "// >>> ai_filemetadata (managed by entrypoint, do not edit this block)";
        $end   = "// <<< ai_filemetadata";
        $store = "config/system/.openai-key";
        $key = (string) getenv("OPENAI_API_KEY");
        $origin = "provisioned from OPENAI_API_KEY";
        if ($key === "" && is_file($store)) {
            $key = trim((string) file_get_contents($store));
            $origin = "kept from the previous provisioning";
        }
        if ($key !== "") {
            file_put_contents($store, $key);
            chmod($store, 0600);
        }
        $block = $begin . "\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"ai_filemetadata\"][\"imageResizing\"] = \"512\";\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"ai_filemetadata\"][\"generateAltTextOnFileUpload\"] = \"1\";\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"ai_filemetadata\"][\"generateAltTextInFrontend\"] = \"0\";\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"ai_filemetadata\"][\"enableTokenTracking\"] = \"1\";\n";
        if ($key !== "") {
            $block .= "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"ai_filemetadata\"][\"apiKey\"] = "
                . var_export($key, true) . ";\n";
        }
        $block .= $end;
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
        echo "additional.php: ai_filemetadata configured, OpenAI key "
            . ($key !== "" ? $origin : "NOT set - alt-text generation will fail")
            . "." . PHP_EOL;
    ' || echo "WARNING: failed to write ai_filemetadata additional.php block" >&2
fi

# Configure nr_textdb (database-backed frontend translations).
# textDbPid MUST match the sysfolder seeded in data/seed-extensions.sql (uid
# 163). With textDbPid = 0 every repository queries pid 0
# (Classes/Domain/Repository/AbstractRepository.php), the backend module lists
# nothing and silently writes orphaned records.
# createIfMissing = 1 is the extension's own shipped default: a key rendered
# through the ViewHelpers for the first time creates its own record.
if [ -f config/system/settings.php ]; then
    php -r '
        $f = "config/system/additional.php";
        $begin = "// >>> nr_textdb (managed by entrypoint, do not edit this block)";
        $end   = "// <<< nr_textdb";
        $block = $begin . "\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"nr_textdb\"][\"textDbPid\"] = \"163\";\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"nr_textdb\"][\"createIfMissing\"] = \"1\";\n"
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
        echo "additional.php: nr_textdb configured (textDbPid=163, createIfMissing=1)." . PHP_EOL;
    ' || echo "WARNING: failed to write nr_textdb additional.php block" >&2
fi

# Configure contexts (netresearch/contexts) for the GET-parameter demo.
# settings.php sets FE.cacheHash.enforceValidation = true, so a request carrying
# an unknown cache-relevant query parameter without a valid cHash is rejected.
# The demo context matches on ?nrdemo=mobile, so that parameter must be excluded
# from the cHash or /extensions/contexts?nrdemo=mobile returns 404 instead of
# switching channels. The extension does not register the exclusion itself: it
# expects the integrator to do it (see its PageCacheIdentifierEventListener,
# which puts the parameter VALUES into the page cache identifier precisely
# because they are excluded from the cHash). Channel-specific caching therefore
# still works -- each channel gets its own page cache entry.
# additional.php is included after the DefaultConfiguration/settings.php merge,
# so appending here extends the core default list rather than replacing it.
if [ -f config/system/settings.php ]; then
    php -r '
        $f = "config/system/additional.php";
        $begin = "// >>> contexts (managed by entrypoint, do not edit this block)";
        $end   = "// <<< contexts";
        $block = $begin . "\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"FE\"][\"cacheHash\"][\"excludedParameters\"][] = \"nrdemo\";\n"
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
        echo "additional.php: contexts cacheHash exclusion for \"nrdemo\" registered." . PHP_EOL;
    ' || echo "WARNING: failed to write contexts additional.php block" >&2
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
# ---------------------------------------------------------------------------
# Demo records for contexts and nr_textdb.
# ---------------------------------------------------------------------------
# These MUST run after extension:setup, not from data/seed-extensions.sql:
# neither tx_contexts_contexts / tx_nrtextdb_domain_model_* nor the
# pages/tt_content tx_contexts_* columns exist when that file is imported, and
# the mariadb client aborts the whole import on the first unknown-table error.
# Same reason the lochmueller/index configuration row lives down here.
# Idempotent: guarded INSERTs plus UPDATEs that re-apply the assignment on
# every boot (INSERT IGNORE never updates an existing row).
if [ -f config/system/settings.php ]; then
    echo "Seeding contexts and nr_textdb demo records..."
    MYSQL_PWD="${MARIADB_PASSWORD:-typo3}" mariadb -h"${MARIADB_HOST:-db}" -u"${MARIADB_USER:-typo3}" "${MARIADB_DATABASE:-typo3}" --default-character-set=utf8mb4 2>/dev/null <<'SQL' || echo "WARNING: contexts/nr_textdb seed failed" >&2
-- The "Demo channel" context: matches while ?nrdemo=mobile is present.
-- pid 1 keeps the record reachable via Web > List on the demo home page;
-- ctrl.rootLevel = -1 plus security.ignorePageTypeRestriction permit it there.
-- alias is eval'd as alphanum_x,nospace,unique,lower -- "mobile" is valid.
INSERT INTO tx_contexts_contexts
    (uid, pid, tstamp, crdate, deleted, disabled, hide_in_backend, type, title, alias, invert, use_session, type_conf)
SELECT 1, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0, 0, 0, 'getparam', 'Demo channel (mobile)', 'mobile', 0, 0,
'<?xml version="1.0" encoding="utf-8" standalone="yes" ?>
<T3FlexForms>
    <data>
        <sheet index="sDEF">
            <language index="lDEF">
                <field index="field_name"><value index="vDEF">nrdemo</value></field>
                <field index="field_values"><value index="vDEF">mobile</value></field>
            </language>
        </sheet>
    </data>
</T3FlexForms>'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM tx_contexts_contexts WHERE uid = 1);

-- Context assignment for the two demo elements and their German translations.
-- The columns hold a comma-separated list of context uids, matched with
-- FIND_IN_SET by the extension's ContextRestriction. Re-applied every boot.
-- Deliberately NOT set on pages: a page-level restriction would hide the whole
-- demo page (and its menu entry) from the default channel.
UPDATE tt_content SET tx_contexts_enable  = '1' WHERE uid IN (606, 621);
UPDATE tt_content SET tx_contexts_disable = '1' WHERE uid IN (607, 622);

-- nr_textdb baseline records in the seeded sysfolder (pages uid 163), so the
-- backend module is not empty on first open. Unique keys are (name, pid,
-- deleted) and (sys_language_uid, pid, environment, component, type,
-- placeholder, deleted), which makes INSERT IGNORE idempotent.
INSERT IGNORE INTO tx_nrtextdb_domain_model_environment (uid, pid, tstamp, crdate, deleted, hidden, name)
VALUES (1, 163, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0, 0, 'default');

INSERT IGNORE INTO tx_nrtextdb_domain_model_component (uid, pid, tstamp, crdate, deleted, hidden, name)
VALUES (1, 163, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0, 0, 'demo');

INSERT IGNORE INTO tx_nrtextdb_domain_model_type (uid, pid, tstamp, crdate, deleted, hidden, name)
VALUES (1, 163, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0, 0, 'label');

-- English source strings (sys_language_uid 0) ...
INSERT IGNORE INTO tx_nrtextdb_domain_model_translation
    (uid, pid, tstamp, crdate, sys_language_uid, l10n_parent, l10n_source, deleted, hidden, sorting,
     environment, component, type, placeholder, value)
VALUES
  (1, 163, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0, 0, 0, 0, 0, 16, 1, 1, 1, 'demo.cta.headline',  'Talk to us'),
  (2, 163, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0, 0, 0, 0, 0, 32, 1, 1, 1, 'demo.cta.button',    'Request a demo'),
  (3, 163, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0, 0, 0, 0, 0, 48, 1, 1, 1, 'demo.form.submit',   'Send message'),
  (4, 163, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0, 0, 0, 0, 0, 64, 1, 1, 1, 'demo.form.thankyou', 'Thanks, we will get back to you.');

-- ... and their German translations (sys_language_uid 1), so the module's
-- "translated" view has a second column to show and the extension demonstrates
-- what it exists for. This table uses l10n_parent (not tt_content's
-- l18n_parent) as its TCA transOrigPointerField.
INSERT IGNORE INTO tx_nrtextdb_domain_model_translation
    (uid, pid, tstamp, crdate, sys_language_uid, l10n_parent, l10n_source, deleted, hidden, sorting,
     environment, component, type, placeholder, value)
VALUES
  (5, 163, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 1, 1, 1, 0, 0, 16, 1, 1, 1, 'demo.cta.headline',  'Sprechen Sie uns an'),
  (6, 163, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 1, 2, 2, 0, 0, 32, 1, 1, 1, 'demo.cta.button',    'Demo anfragen'),
  (7, 163, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 1, 3, 3, 0, 0, 48, 1, 1, 1, 'demo.form.submit',   'Nachricht senden'),
  (8, 163, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 1, 4, 4, 0, 0, 64, 1, 1, 1, 'demo.form.thankyou', 'Danke, wir melden uns.');
SQL
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
