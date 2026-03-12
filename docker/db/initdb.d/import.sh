#!/bin/bash
set -eo pipefail
: "${MARIADB_ROOT_PASSWORD:?MARIADB_ROOT_PASSWORD must be set}"
: "${MARIADB_DATABASE:?MARIADB_DATABASE must be set}"
SEED_FILE="/docker-entrypoint-initdb.d/db.sql.gz"
if [ -f "$SEED_FILE" ]; then
    echo "Importing TYPO3 demo database seed..."
    MYSQL_PWD="${MARIADB_ROOT_PASSWORD}" zcat "$SEED_FILE" | mariadb -u root "${MARIADB_DATABASE}"
    echo "Database seed imported successfully."
else
    echo "No seed file found at $SEED_FILE — starting with empty database."
fi
