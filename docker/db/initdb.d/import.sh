#!/bin/bash
set -e
SEED_FILE="/docker-entrypoint-initdb.d/db.sql.gz"
if [ -f "$SEED_FILE" ]; then
    echo "Importing TYPO3 demo database seed..."
    zcat "$SEED_FILE" | mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" "${MARIADB_DATABASE}"
    echo "Database seed imported successfully."
else
    echo "No seed file found at $SEED_FILE — starting with empty database."
fi
