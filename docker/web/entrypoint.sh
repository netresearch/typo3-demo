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

# fileadmin lives in a volume that outlives the image, so a file added to
# data/fileadmin/ after the first boot never reached the instance: the copy
# below used to run only while the volume was empty, and it has not been empty
# since March. Sixteen extension icons and a demo source file shipped as 404s
# before this was noticed — the pages referenced them and nobody fetched one.
#
# Two passes, because the volume holds two kinds of file:
#   1. -n adds what the image carries and the volume lacks, and never clobbers
#      anything uploaded through the backend.
#   2. Directories the repository owns outright are refreshed, so a corrected
#      asset actually arrives instead of being pinned by pass 1.
if [ -d /seed/fileadmin ]; then
    echo "Syncing fileadmin from image..."
    # Copied file by file, not with `cp -n`. BusyBox cp — which is what this
    # alpine image has — treats `cp -a -n src/. dst/` as "destination exists,
    # skip", and copies NOTHING: measured 0 of 227 files. GNU cp does the
    # obvious thing, which is why a test on the build host says it works.
    (cd /seed/fileadmin && find . -type f) | while IFS= read -r f; do
        if [ ! -e "public/fileadmin/$f" ]; then
            mkdir -p "public/fileadmin/$(dirname "$f")"
            cp -a "/seed/fileadmin/$f" "public/fileadmin/$f"
        fi
    done

    for owned in user_upload/images/extension-icons user_upload/repurpose; do
        if [ -d "/seed/fileadmin/$owned" ]; then
            mkdir -p "public/fileadmin/$owned"
            cp -a "/seed/fileadmin/$owned/." "public/fileadmin/$owned/"
        fi
    done

    chown -R www-data:www-data public/fileadmin
    echo "Fileadmin synced."
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

# Serve processed images as WebP. TYPO3 14 decides the target format of every
# processed image from GFX.imageFileConversionFormats (Feature 93981); the core
# default keeps jpg as jpg, png as png and turns everything else into png, which
# is why this demo delivered no modern format at all.
#
# Only svg is exempt, because rasterising a vector is a downgrade. Everything
# else - jpg, png, pdf previews, backend thumbnails - becomes webp.
#
# Measured on a local 14.3.6 with one of this demo images: 94899 bytes as png,
# 15820 as webp. avif was tried too and came out at 18104 bytes, so it is bigger
# than webp at the core default quality of 85 and buys nothing here.
#
# Not written into the settings.php heredoc above: that one runs only on first
# boot, so an instance that already exists would never see it.
#
# This needs the encoders in the image (see the Dockerfile); without them
# ImageMagick fails the conversion instead of producing anything.
if [ -f config/system/settings.php ]; then
    php -r '
        $f = "config/system/additional.php";
        $begin = "// >>> gfx image conversion (managed by entrypoint, do not edit this block)";
        $end   = "// <<< gfx image conversion";
        // No apostrophes in these comments: the whole block is a php -r
        // argument inside single quotes, and one would end the shell string.
        $block = $begin . "\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"GFX\"][\"imageFileConversionFormats\"] = [\"svg\" => \"svg\", \"default\" => \"webp\"];\n"
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
        echo "additional.php: processed images are converted to webp." . PHP_EOL;
    ' || echo "WARNING: failed to write the GFX block to additional.php" >&2
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
            // Turn on the specialized services of nr_llm. isAvailable() on all
            // three (DALL-E, Whisper, TTS) is just "an apiKeyIdentifier is set
            // and that vault secret exists" - the identifier was empty, so the
            // podcast and image artifacts of Repurpose failed with "speech
            // synthesis unavailable" / "image service unavailable". It is the
            // same secret everything else already uses.
            // No apostrophes in these comments: the whole block is a php -r
            // argument inside single quotes, and one would end the shell string.
            // Switches on the specialized services of nr_llm (DALL-E, Whisper,
            // TTS). isAvailable() is only "an apiKeyIdentifier is set and that
            // vault secret exists", and it is the same secret everything else
            // uses.
            //
            // This line was briefly disabled on the theory that it broke the
            // rendered artifacts. It did not: the cause was the alt-text
            // listener firing on the CLI, fixed separately. With that fixed the
            // job produces all ten artifacts, podcast and AI images included.
            //
            // Note for anyone reading this after a deploy: extension:setup
            // persists EXTENSIONS.nr_llm into config/system/settings.php, so on
            // an instance that has run once the value survives even without this
            // line. A FRESH install has no such settings.php, which is why the
            // line has to stay here.
            //
            // No apostrophes in these comments: the whole block is a php -r
            // argument inside single quotes, and one would end the shell string.
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"nr_llm\"][\"providers\"][\"openai\"][\"apiKeyIdentifier\"] = \"openai_api_key\";\n"
            // nr_llm defaults to dall-e-3, which this account does not serve:
            //   400 The model dall-e-3 does not exist.
            // gpt-image-1 answers 200 with an image. Measured, not assumed - the
            // same class of mistake that made the chat model fail twice.
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"nr_llm\"][\"image\"][\"dalle\"][\"defaultModel\"] = \"gpt-image-1\";\n"
            // tts-1 is the nr_llm default and answers with real audio here.
            // Set explicitly so the value is visible rather than implicit.
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"nr_llm\"][\"speech\"][\"tts\"][\"defaultModel\"] = \"tts-1\";\n"
            // nr_repurpose 0.4.2 runs its generation job as this backend user.
            // Without it the setting stays 0, the job keeps booting an
            // unauthenticated CLI user, and nr_vault denies the provider key --
            // which is the failure the release fixes but does not configure.
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"nr_repurpose\"][\"technicalBeUserUid\"] = \"992\";\n"
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
        echo "additional.php: nr_ai_search configured (technicalBeUserUid=990, dims=1536), nr_vault provisioning actor 991, nr_repurpose actor 992, nr_llm media on (gpt-image-1/tts-1), index dev-sync on." . PHP_EOL;
    ' || echo "WARNING: failed to write nr_ai_search additional.php block" >&2
fi

# Configure ai_filemetadata (AI-generated alternative texts for FAL images).
#
# This one goes into settings.php, NOT additional.php, and that distinction is
# the whole point. The extension reads its behaviour settings through
# ConfigurationService -> ConfigurationManager::getMergedLocalConfiguration(),
# which is getDefaultConfiguration() merged with `require settings.php` — it
# never looks at additional.php. Only `apiKey` would have arrived that way,
# because ExtensionConfiguration::get() reads $GLOBALS, which additional.php
# does populate. The other four would have fallen back to the catch-defaults in
# ConfigurationService::loadConfiguration(), and those fail OPEN:
# imageResizing 0 (no downscaling, full-resolution images billed by the pixel)
# and generateAltTextInFrontend true (a synchronous OpenAI call while a visitor
# waits for the page). Writing settings.php is what the extension actually reads,
# and it is the file ExtensionConfiguration::set() writes too.
#
# Editing settings.php from here follows the installToolPassword step above:
# read the array, change the keys we own, write it back with var_export.
#
# No sidecar file. settings.php lives in the typo3-config volume, so a boot
# without OPENAI_API_KEY simply keeps the key already stored there. The key ends
# up in settings.php in plaintext either way — this extension has no nr-vault
# support, and `typo3 extension:setup` would copy it there regardless — so it is
# stored where MARIADB_PASSWORD already lives rather than in a second place.
if [ -f config/system/settings.php ]; then
    php -r '
        $f = "config/system/settings.php";
        $cfg = include $f;
        if (!is_array($cfg)) {
            fwrite(STDERR, "settings.php did not return an array" . PHP_EOL);
            exit(1);
        }
        $ext = $cfg["EXTENSIONS"]["ai_filemetadata"] ?? [];
        $key = (string) getenv("OPENAI_API_KEY");
        $origin = "provisioned from OPENAI_API_KEY";
        if ($key === "") {
            $key = (string) ($ext["apiKey"] ?? "");
            $origin = "kept from the previous provisioning";
        }
        // Cost control, not a quality setting: images are billed by the pixel and
        // a 50-word alt text does not need full resolution.
        $ext["imageResizing"] = "512";
        $ext["generateAltTextOnFileUpload"] = "1";
        // A missing alt text must not trigger a synchronous API call while a
        // visitor waits for the page.
        $ext["generateAltTextInFrontend"] = "0";
        $ext["enableTokenTracking"] = "1";
        if ($key !== "") {
            $ext["apiKey"] = $key;
        }
        $cfg["EXTENSIONS"]["ai_filemetadata"] = $ext;

        // Write to a sibling and rename. file_put_contents() truncates in place,
        // and settings.php is the one file whose corruption bricks the instance:
        // a partial write (full volume) leaves a parse error, the
        // installToolPassword step above then dies under `set -eu` before nginx
        // starts, and no boot regenerates the file because it still exists.
        // rename() within the same directory is atomic, so a reader either sees
        // the old file or the new one - never half of either. That also closes
        // the window in which a php-fpm request could include a half-written file.
        $tmp = $f . ".tmp";
        $payload = "<?php\nreturn " . var_export($cfg, true) . ";\n";
        $written = @file_put_contents($tmp, $payload);
        if ($written === false || $written !== strlen($payload)) {
            @unlink($tmp);
            fwrite(STDERR, "failed to write " . $tmp . " (wrote " . var_export($written, true)
                . " of " . strlen($payload) . " bytes) - settings.php left untouched" . PHP_EOL);
            exit(1);
        }
        // Verify the candidate before it replaces anything.
        $check = include $tmp;
        if (!is_array($check) || ($check["EXTENSIONS"]["ai_filemetadata"]["imageResizing"] ?? null) !== "512") {
            @unlink($tmp);
            fwrite(STDERR, "the new settings.php did not parse back - settings.php left untouched" . PHP_EOL);
            exit(1);
        }
        $perms = @fileperms($f);
        if ($perms !== false) {
            @chmod($tmp, $perms & 0777);
        }
        if (!@rename($tmp, $f)) {
            @unlink($tmp);
            fwrite(STDERR, "failed to rename " . $tmp . " over settings.php - settings.php left untouched" . PHP_EOL);
            exit(1);
        }
        echo "settings.php: ai_filemetadata configured, OpenAI key "
            . ($key !== "" ? $origin : "NOT set - alt-text generation will fail")
            . "." . PHP_EOL;
    ' || echo "WARNING: ai_filemetadata is NOT configured - settings.php was left untouched, so alt-text generation runs on the extension's fail-open defaults (no image downscaling, frontend generation on)" >&2
fi

# Configure autotranslate (DeepL).
#
# The extension reads its key from the extension configuration or from the site
# configuration and knows nothing about nr_vault, so the key cannot take the
# route OPENAI_API_KEY takes. It arrives as DEEPL_API_KEY in the container
# environment (compose.yml passes it through; `make provision-deepl-key` puts it
# into the host .env so it survives a reboot).
#
# apiKey is only written when the variable is non-empty. An empty variable must
# not wipe a key that a previous boot stored in this volume — same rule as
# provision-llm-key: a missing secret degrades the feature, it never breaks what
# already works.
#
# debug = 1 on purpose. autotranslate's LogUtility drops EVERY log line,
# including errors, while debug is off (upstream issue #157), and its batch
# runner reports "done" even when nothing was translated (upstream issue #156).
# On this instance the log is the only place a failed translation shows up.
if [ -f config/system/settings.php ]; then
    php -r '
        $f = "config/system/additional.php";
        $begin = "// >>> autotranslate (managed by entrypoint, do not edit this block)";
        $end   = "// <<< autotranslate";
        // The key is kept in a sidecar file in the same volume rather than parsed
        // back out of the block on the next boot: additional.php is loaded on
        // every request, and a half-matched literal there takes the whole site
        // down. A file read cannot produce a syntax error.
        $store = "config/system/.deepl-key";
        $key = (string) getenv("DEEPL_API_KEY");
        $origin = "provisioned from DEEPL_API_KEY";
        if ($key === "" && is_file($store)) {
            $key = trim((string) file_get_contents($store));
            $origin = "kept from the previous provisioning";
        }
        if ($key !== "") {
            file_put_contents($store, $key);
            chmod($store, 0600);
        }
        $block = $begin . "\n"
            . "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"autotranslate\"][\"debug\"] = \"1\";\n";
        if ($key !== "") {
            $block .= "\$GLOBALS[\"TYPO3_CONF_VARS\"][\"EXTENSIONS\"][\"autotranslate\"][\"apiKey\"] = "
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
        echo "additional.php: autotranslate debug on, DeepL key "
            . ($key !== "" ? $origin : "NOT set - translations will silently do nothing")
            . "." . PHP_EOL;
    ' || echo "WARNING: failed to write autotranslate additional.php block" >&2
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
