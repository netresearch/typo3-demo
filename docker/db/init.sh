#!/bin/sh
# Database bootstrap for the hardened MariaDB image.
#
# The Docker Hardened Image ships a deliberately minimal entrypoint: it honours
# MARIADB_ROOT_PASSWORD and nothing else. It does not create MARIADB_DATABASE /
# MARIADB_USER and it does not process /docker-entrypoint-initdb.d, so both live
# here and run as the one-shot `db-init` service once the server is healthy.
#
# Idempotent by design: the grants are re-applied on every start (cheap, and it
# picks up a rotated MARIADB_PASSWORD), the seed is imported only into a
# database that has no tables yet — live data always wins over the repo seed.
set -eu

: "${MARIADB_ROOT_PASSWORD:?must be set}"
: "${MARIADB_DATABASE:?must be set}"
: "${MARIADB_USER:?must be set}"
: "${MARIADB_PASSWORD:?must be set}"

SEED_FILE=/seed/db.sql.gz
# MYSQL_PWD instead of -p: keeps the password out of the process list.
export MYSQL_PWD="${MARIADB_ROOT_PASSWORD}"
mariadb -h db -u root <<SQL
-- mariadb-install-db leaves anonymous accounts behind and the hardened
-- entrypoint, unlike the official one, does not clear them. Besides being a
-- weakness in their own right, an anonymous ''@'localhost' shadows the
-- application user on socket connections — which is how every client helper in
-- this repo (make db-shell, make export-seed, the diagnostics and BE-reset
-- workflows) reaches the database.
DELETE FROM mysql.global_priv WHERE User = '';

-- ... but the anonymous account was also what let healthcheck.sh in: it
-- connects through the socket as the OS user mysql with no password. The
-- official image provisions a real account for that (MARIADB_MYSQL_LOCALHOST_USER),
-- authenticated by the unix_socket plugin, so no password exists to leak.
CREATE USER IF NOT EXISTS 'mysql'@'localhost' IDENTIFIED VIA unix_socket;
-- PROCESS: --innodb_initialized reads information_schema.INNODB_* tables.
GRANT USAGE, PROCESS ON *.* TO 'mysql'@'localhost';

CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Both hosts: '%' for the app containers over the network, 'localhost' for
-- clients run inside the db container through the socket.
CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
ALTER USER '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';
CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'localhost' IDENTIFIED BY '${MARIADB_PASSWORD}';
ALTER USER '${MARIADB_USER}'@'localhost' IDENTIFIED BY '${MARIADB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL
echo "db-init: database ${MARIADB_DATABASE} and user ${MARIADB_USER} ready"

tables=$(mariadb -h db -u root -N -B -e \
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${MARIADB_DATABASE}'")
if [ "${tables}" -gt 0 ]; then
    echo "db-init: ${MARIADB_DATABASE} already holds ${tables} tables — not seeding"
    exit 0
fi
if [ ! -f "${SEED_FILE}" ]; then
    echo "db-init: no seed at ${SEED_FILE} — leaving the database empty"
    exit 0
fi

echo "db-init: importing the demo seed into an empty ${MARIADB_DATABASE}"
# The hardened image carries no gzip; its zstd reads gzip streams.
zstd -dc "${SEED_FILE}" | mariadb -h db -u root "${MARIADB_DATABASE}"
echo "db-init: seed imported"
