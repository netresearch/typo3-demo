---
type: Instance Component
title: "Composer manifest"
description: "composer.json and composer.lock: which extensions the instance installs, in which versions."
status: draft
timestamp: 2026-11-27
---

# Definition

The Composer manifest is `composer.json` with the allowed ranges and `composer.lock` with the resolved versions. An extension update on the demo is always a full update of all Netresearch extensions, the lock file and the base images.

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `implementedBy` | `composer.json` | `AGENTS.md` | `An extension update on the demo is always a full update` | asserted |
