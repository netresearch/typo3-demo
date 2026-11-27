---
type: Instance Component
title: "Seed data"
description: "The database dump data/db.sql.gz with the demo content, landing-page templates, dashboards and nr-llm records."
status: draft
timestamp: 2026-11-27
---

# Definition

The seed data is the database dump `data/db.sql.gz`. It holds the demo content, the landing-page templates, both dashboards and the demo editors. A workflow exports a sanitized dump from the live instance.

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `implementedBy` | `data/db.sql.gz` | `.github/workflows/export-seed.yml` | `name: Export DB Seed` | asserted |
