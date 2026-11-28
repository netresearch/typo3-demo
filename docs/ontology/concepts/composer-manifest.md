---
type: Instance Component
title: "Composer manifest"
description: "composer.json and composer.lock: which extensions the instance installs, in which versions."
status: draft
timestamp: 2026-11-27
---

# Definition

The Composer manifest is `composer.json` with the allowed ranges and `composer.lock` with the resolved versions. An extension update on the demo is always a full update of all Netresearch extensions, the lock file and the base images.

# Neighbours

Generated from the relation tables by `check-ontology.py --write-diagrams`. A solid arrow is an asserted relation, a dotted arrow a hypothesis; a slanted box is a file of the repository.

```mermaid
flowchart LR
  c["Composer manifest"]
  n1[/"composer.json"/]
  n2["Container image"]
  c -->|"implementedBy"| n1
  n2 -->|"derivedFrom"| c
  classDef focus fill:#2F99A4,stroke:#15585E,color:#ffffff
  class c focus
```

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `implementedBy` | `composer.json` | `AGENTS.md` | `An extension update on the demo is always a full update` | asserted |
