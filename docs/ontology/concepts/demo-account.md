---
type: Instance Component
title: "Demo account"
description: "The backend accounts of the demo, among them the admin nr_admin and the AI editor redakteur_ki with a small AI budget."
status: draft
timestamp: 2026-11-27
---

# Definition

The demo accounts are backend users of the seed data. `nr_admin` is the administrator. `redakteur_ki` is a non-admin editor with the AI Tasks module and a small AI budget; the module and the Cowriter dialog show its own usage. The other demo editors have no password and are entered through "Switch to user".

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `uses` | [netresearch/nr-llm](extensions/nr-llm.md) | `README.md` | `a non-admin with the AI Tasks module and a` | asserted |
| `derivedFrom` | [Seed data](seed-data.md) | `README.md` | `have no password and are entered` | asserted |
