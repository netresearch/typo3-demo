---
type: Instance Component
title: "Cache"
description: "Valkey, the key-value store behind the TYPO3 caches."
status: draft
timestamp: 2026-11-27
---

# Definition

The cache is Valkey (`valkey/valkey`), the key-value store the TYPO3 caches use.

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `implementedBy` | `compose.yml` | `compose.yml` | `image: valkey/valkey:` | asserted |
