---
type: Instance
title: "TYPO3 demo instance"
description: "The live TYPO3 14 showcase of the Netresearch extensions at typo3-demo.netresearch.de."
status: draft
timestamp: 2026-11-27
---

# Definition

The demo instance is the live, disposable TYPO3 14 showcase of the Netresearch extension suite at https://typo3-demo.netresearch.de/. It runs the same container stack in local development and in production.

# Not to be confused with

- The TYPO3 AI Edition. The edition is a Composer package of tested versions; this instance requires the extensions individually.

# Neighbours

Generated from the relation tables by `check-ontology.py --write-diagrams`. A solid arrow is an asserted relation, a dotted arrow a hypothesis; a slanted box is a file of the repository.

```mermaid
flowchart LR
  c["TYPO3 demo instance"]
  n1[/"compose.yml"/]
  n2["Application container"]
  n3["Cache"]
  n4["Database"]
  n5["Proxy"]
  n6["Deployment"]
  c -->|"implementedBy"| n1
  c -->|"uses"| n2
  c -->|"uses"| n3
  c -->|"uses"| n4
  c -->|"uses"| n5
  n6 -->|"uses"| c
  classDef focus fill:#2F99A4,stroke:#15585E,color:#ffffff
  class c focus
```

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `uses` | [Application container](app-container.md) | `compose.yml` | `dockerfile: docker/web/Dockerfile` | asserted |
| `uses` | [Database](database.md) | `compose.yml` | `- typo3-db-v2:/var/lib/mysql` | asserted |
| `uses` | [Cache](cache.md) | `compose.yml` | `image: valkey/valkey:` | asserted |
| `uses` | [Proxy](proxy.md) | `compose.yml` | `image: dhi.io/caddy:` | asserted |
| `implementedBy` | `compose.yml` | `compose.yml` | `name: typo3-demo` | asserted |
