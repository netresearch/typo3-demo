---
type: Instance Component
title: "Database"
description: "MariaDB from the Docker Hardened Image, created and seeded by the one-shot db-init service."
status: draft
timestamp: 2026-11-27
---

# Definition

The database is MariaDB from the Docker Hardened Image (`dhi.io/mariadb`). Its entrypoint creates no application database, so the one-shot service `db-init` creates the database and the user and imports the seed data on the first boot.

# Neighbours

Generated from the relation tables by `check-ontology.py --write-diagrams`. A solid arrow is an asserted relation, a dotted arrow a hypothesis; a slanted box is a file of the repository.

```mermaid
flowchart LR
  c["Database"]
  n1[/"compose.yml"/]
  n2["Seed data"]
  n3["Application container"]
  n4["Demo account"]
  n5["TYPO3 demo instance"]
  c -->|"implementedBy"| n1
  c -->|"uses"| n2
  n3 -.->|"uses (hypothesis)"| c
  n4 -->|"uses"| c
  n5 -->|"uses"| c
  classDef focus fill:#2F99A4,stroke:#15585E,color:#ffffff
  class c focus
```

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `uses` | [Seed data](seed-data.md) | `docker/db/init.sh` | `SEED_FILE=/seed/db.sql.gz` | asserted |
| `implementedBy` | `compose.yml` | `compose.yml` | `db: image: dhi.io/mariadb:12` | asserted |
