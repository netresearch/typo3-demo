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

echo "Verifying sanitization..."
KEYS=$(echo "SELECT COALESCE(MAX(LENGTH(api_key)), 0) FROM tx_nrllm_provider;" | sql -N "$SCRATCH")
SECRETS=$(echo "SELECT COUNT(*) FROM tx_nrvault_secret;" | sql -N "$SCRATCH")
LOGS=$(echo "SELECT COUNT(*) FROM sys_log;" | sql -N "$SCRATCH")
if [ "$KEYS" != "0" ] || [ "$SECRETS" != "0" ] || [ "$LOGS" != "0" ]; then
    echo "ERROR: sanitization failed (api_key_len=$KEYS vault_rows=$SECRETS sys_log_rows=$LOGS)" >&2
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
