#!/bin/bash
# Sanitized DB seed export for the PUBLIC repository.
#
# Copies the live database into a scratch schema, strips everything that
# must not be published (API keys, vault secrets, logs, sessions, caches,
# telemetry), and writes the gzipped dump to /tmp/typo3-demo-seed.sql.gz.
# Passkey credentials (public-key material only) are intentionally kept so
# a re-seeded instance retains passkey login.
#
# Run on the demo host from the repo root: bash scripts/export-seed-sanitized.sh
set -euo pipefail
cd "$(dirname "$0")/.."

OUT=/tmp/typo3-demo-seed.sql.gz
SCRATCH=seed_export
DB_NAME=$(docker compose exec -T db sh -c 'printf %s "${MARIADB_DATABASE:-typo3}"')

sql() { # sql [mariadb-args...]: run SQL from stdin as root against the db container
    docker compose exec -T db sh -c \
        'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" mariadb -u root "$@"' sh "$@"
}

dump() { # dump <database>: mariadb-dump a database to stdout
    docker compose exec -T db sh -c \
        'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" mariadb-dump -u root --single-transaction --quick --skip-lock-tables "$@"' sh "$@"
}

echo "Cloning live database '$DB_NAME' into scratch schema '$SCRATCH'..."
echo "DROP DATABASE IF EXISTS $SCRATCH; CREATE DATABASE $SCRATCH;" | sql
dump "$DB_NAME" | sql "$SCRATCH"

echo "Sanitizing..."
echo "UPDATE tx_nrllm_provider SET api_key = '';" | sql "$SCRATCH"

# Volatile and sensitive tables: publish structure, never content.
echo "SELECT table_name FROM information_schema.tables
      WHERE table_schema='$SCRATCH'
        AND (table_name LIKE 'cache\\_%'
          OR table_name LIKE '%\\_sessions'
          OR table_name IN (
            'sys_log', 'sys_history', 'sys_lockedrecords',
            'sys_messenger_messages', 'sys_http_report',
            'tx_nrvault_secret', 'tx_nrvault_secret_begroups_mm',
            'tx_nrvault_secret_writegroups_mm', 'tx_nrvault_audit_log',
            'tx_nrllm_service_usage', 'tx_nrllm_telemetry',
            'tx_nrllm_skill_audit', 'tx_nrllm_eval_result',
            'tx_nrllm_agentrun', 'tx_nrllm_agentrun_event',
            'tx_nrllm_ai_session', 'tx_nrllm_ai_session_message',
            'tx_nrllm_tool_state', 'tx_nrllm_tool_group_state'
          ));" \
    | sql -N "$SCRATCH" \
    | while read -r t; do echo "TRUNCATE TABLE \`$t\`;"; done \
    | sql "$SCRATCH"

# Workspace records: never publish them.
#
# A record that lives only in a workspace (t3ver_wsid <> 0) has no live
# counterpart, so RootlineUtility cannot resolve it in workspace 0 and answers
# "Broken rootline. Could not resolve page with uid <n>." Every consumer of the
# rootline then fails — including the localization wizard, which is how this was
# found (NEXT-127: page 119, a sysfolder that existed only in the auto-created
# "MCP Workspace"). Publishing or discarding a workspace is an editorial
# decision on the live instance; a seed for a fresh install must carry neither.
echo "Purging workspace records..."
echo "SELECT table_name FROM information_schema.columns
      WHERE table_schema='$SCRATCH' AND column_name='t3ver_wsid';" \
    | sql -N "$SCRATCH" \
    | while read -r t; do echo "DELETE FROM \`$t\` WHERE t3ver_wsid <> 0;"; done \
    | sql "$SCRATCH"
echo "DELETE FROM sys_refindex WHERE workspace <> 0;" | sql "$SCRATCH"
# sys_preview holds workspace preview links keyed by a hash. It has no
# t3ver_wsid column, so the loop above misses it, and its rows would name
# whatever workspace uid a fresh install happens to create next.
# be_users.workspace_id would likewise point at a workspace that no longer
# exists; TYPO3 falls back to live, but the seed should not ship the dangling
# value in the first place.
echo "DELETE FROM sys_preview;
      UPDATE be_users SET workspace_id = 0 WHERE workspace_id <> 0;" | sql "$SCRATCH"
# sys_workspace* only exist with EXT:workspaces installed. Truncating them
# unconditionally makes the export unrunnable on an installation without it.
for t in sys_workspace sys_workspace_stage; do
    if [ "$(echo "SELECT COUNT(*) FROM information_schema.tables
                  WHERE table_schema='$SCRATCH' AND table_name='$t';" | sql -N "$SCRATCH")" != "0" ]; then
        echo "TRUNCATE TABLE \`$t\`;" | sql "$SCRATCH"
    fi
done

echo "Verifying sanitization..."
KEYS=$(echo "SELECT COALESCE(MAX(LENGTH(api_key)), 0) FROM tx_nrllm_provider;" | sql -N "$SCRATCH")
SECRETS=$(echo "SELECT COUNT(*) FROM tx_nrvault_secret;" | sql -N "$SCRATCH")
LOGS=$(echo "SELECT COUNT(*) FROM sys_log;" | sql -N "$SCRATCH")
if [ "$KEYS" != "0" ] || [ "$SECRETS" != "0" ] || [ "$LOGS" != "0" ]; then
    echo "ERROR: sanitization failed (api_key_len=$KEYS vault_rows=$SECRETS sys_log_rows=$LOGS)" >&2
    exit 1
fi

# Sum the leftovers across every versioned table, not just pages: one
# unpublished content element is enough to break the page it sits on.
WS_TABLES=$(echo "SELECT COUNT(*) FROM information_schema.columns
                  WHERE table_schema='$SCRATCH' AND column_name='t3ver_wsid';" | sql -N "$SCRATCH")
# A gate that inspects nothing passes everything: the loop below re-runs the
# same information_schema query the purge used, so an empty result would make
# both the purge and its verification vacuous. TYPO3 always has pages and
# tt_content, so a plausible floor is cheap insurance.
if [ "$WS_TABLES" -lt 2 ]; then
    echo "ERROR: only $WS_TABLES versioned tables found - the purge inspected nothing." >&2
    exit 1
fi
WS_ROWS=0
for t in $(echo "SELECT table_name FROM information_schema.columns
                 WHERE table_schema='$SCRATCH' AND column_name='t3ver_wsid';" | sql -N "$SCRATCH"); do
    n=$(echo "SELECT COUNT(*) FROM \`$t\` WHERE t3ver_wsid <> 0;" | sql -N "$SCRATCH")
    WS_ROWS=$((WS_ROWS + n))
done
# Everything the purge touched is re-counted, not just the versioned tables.
# sys_workspace is counted separately because it may legitimately not exist;
# a missing table inside the arithmetic below would abort the whole statement.
WORKSPACES=$(echo "SELECT
      (SELECT COUNT(*) FROM sys_refindex WHERE workspace <> 0)
    + (SELECT COUNT(*) FROM sys_preview)
    + (SELECT COUNT(*) FROM be_users WHERE workspace_id <> 0);" | sql -N "$SCRATCH")
if [ "$(echo "SELECT COUNT(*) FROM information_schema.tables
              WHERE table_schema='$SCRATCH' AND table_name='sys_workspace';" | sql -N "$SCRATCH")" != "0" ]; then
    WORKSPACES=$((WORKSPACES + $(echo "SELECT COUNT(*) FROM sys_workspace;" | sql -N "$SCRATCH")))
fi
if [ "$WS_ROWS" != "0" ] || [ "$WORKSPACES" != "0" ]; then
    echo "ERROR: workspace purge failed (versioned_rows=$WS_ROWS workspace_leftovers=$WORKSPACES over $WS_TABLES versioned tables)" >&2
    exit 1
fi

echo "Exporting to $OUT..."
dump "$SCRATCH" | gzip > "$OUT"
echo "DROP DATABASE $SCRATCH;" | sql

if zcat "$OUT" | grep -q 'INSERT INTO .tx_nrvault_secret.'; then
    echo "ERROR: vault rows present in dump" >&2
    exit 1
fi
PASSKEYS=$(zcat "$OUT" | grep -c 'INSERT INTO .tx_nrpasskeysbe_credential.' || true)
echo "Done: $(du -h "$OUT" | cut -f1), BE passkey insert statements: $PASSKEYS"
