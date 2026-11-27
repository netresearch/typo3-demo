---
type: Instance Component
title: "Extension seed"
description: "data/seed-extensions.sql and data/seed-falkenquell.sql: demo records, dashboards, landing-page templates, demo editors and nr-llm records, applied again on every deploy."
status: draft
timestamp: 2026-11-27
---

# Definition

The extension seed is `data/seed-extensions.sql` with `data/seed-falkenquell.sql`. It holds the records the extensions need on the demo: the landing-page templates, both dashboards, the demo editors (`redakteur_entwurf`, `redakteur_repurpose`, `redakteur_ki`) and the nr-llm records. `make seed-extensions` applies it idempotently, and `make update`, which the deployment runs, calls it on every deploy. A change to it therefore reaches the live database with the next merge.

# Not to be confused with

- The seed data (`data/db.sql.gz`), which is imported only into an empty database.

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `implementedBy` | `data/seed-extensions.sql` | `Makefile` | `seed-extensions: ## Apply data/seed-extensions.sql and data/seed-falkenquell.sql to the DB` | asserted |
| `uses` | [netresearch/nr-llm](extensions/nr-llm.md) | `data/seed-extensions.sql` | `SELECT 'SEED-PROBLEM: tx_nrllm_user_budget 9304 for redakteur_ki (be_user 1000) missing, foreign or inactive'` | asserted |
