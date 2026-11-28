---
type: Instance Component
title: "Cache"
description: "Valkey, the key-value store behind the TYPO3 caches."
status: draft
timestamp: 2026-11-27
---

# Definition

The cache is Valkey (`valkey/valkey`), the key-value store the TYPO3 caches use.

# Neighbours

Generated from the relation tables by `check-ontology.py --write-diagrams`. A solid arrow is an asserted relation, a dotted arrow a hypothesis; a slanted box is a file of the repository.

```mermaid
flowchart LR
  c["Cache"]
  n1[/"compose.yml"/]
  n2["Application container"]
  n3["TYPO3 demo instance"]
  c -->|"implementedBy"| n1
  n2 -.->|"uses (hypothesis)"| c
  n3 -->|"uses"| c
  classDef focus fill:#2F99A4,stroke:#15585E,color:#ffffff
  class c focus
```

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `implementedBy` | `compose.yml` | `compose.yml` | `image: valkey/valkey:` | asserted |
