---
type: Instance Component
title: "Seed data"
description: "The database dump data/db.sql.gz with the demo content and the admin account, imported only into an empty database."
status: draft
timestamp: 2026-11-27
---

# Definition

The seed data is the database dump `data/db.sql.gz`. It holds the demo content and the admin account `nr_admin`. The service `db-init` imports it only into a database without tables, so live data always wins. A workflow exports a sanitized dump from the live instance. The records the extensions need come from the extension seed.

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `implementedBy` | `data/db.sql.gz` | `.github/workflows/export-seed.yml` | `name: Export DB Seed` | asserted |
