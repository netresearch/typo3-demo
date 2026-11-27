---
type: Instance Component
title: "Cache"
description: "Valkey, the key-value store behind the TYPO3 caches."
status: draft
generated: {by: claude-code/2.1.332, at: 2026-11-27T21:06:57Z}
---

# Definition

The cache is Valkey (`valkey/valkey`), the key-value store the TYPO3 caches use.

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `implementedBy` | `compose.yml` | `compose.yml` | `image: valkey/valkey:9-alpine@sha256:` | asserted |
