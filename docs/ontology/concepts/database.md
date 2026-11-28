---
type: Instance Component
title: "Database"
description: "MariaDB from the Docker Hardened Image, created and seeded by the one-shot db-init service."
status: draft
timestamp: 2026-11-27
---

# Definition

The database is MariaDB from the Docker Hardened Image (`dhi.io/mariadb`). Its entrypoint creates no application database, so the one-shot service `db-init` creates the database and the user and imports the seed data on the first boot.

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `uses` | [Seed data](seed-data.md) | `docker/db/init.sh` | `SEED_FILE=/seed/db.sql.gz` | asserted |
| `implementedBy` | `compose.yml` | `compose.yml` | `db: image: dhi.io/mariadb:12` | asserted |
