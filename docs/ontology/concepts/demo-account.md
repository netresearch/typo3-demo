---
type: Instance Component
title: "Demo account"
description: "The backend accounts of the demo, among them the admin nr_admin and the AI editor redakteur_ki with a small AI budget."
status: draft
timestamp: 2026-11-27
---

# Definition

The demo accounts are backend users in the database. The admin `nr_admin` comes from the seed data, the editors from the extension seed. `nr_admin` is the administrator. `redakteur_ki` is a non-admin editor with the AI Tasks module and a small AI budget; the module and the Cowriter dialog show its own usage. The other demo editors have no password and are entered through "Switch to user".

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `uses` | [netresearch/nr-llm](extensions/nr-llm.md) | `README.md` | `a non-admin with the AI Tasks module and a` | asserted |
| `uses` | [Database](database.md) | `README.md` | `(run once after a fresh install or reset)` | asserted |
| `derivedFrom` | [Extension seed](extension-seed.md) | `data/seed-extensions.sql` | `WHERE uid = 1000 AND username = 'redakteur_ki' AND admin = 0` | asserted |
