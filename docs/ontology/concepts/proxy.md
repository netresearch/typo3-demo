---
type: Instance Component
title: "Proxy"
description: "Caddy, the HTTPS front of the instance."
status: draft
timestamp: 2026-11-27
---

# Definition

The proxy is Caddy (`dhi.io/caddy`), which terminates HTTPS and forwards requests to the web container.

# Neighbours

Generated from the relation tables by `check-ontology.py --write-diagrams`. A solid arrow is an asserted relation, a dotted arrow a hypothesis; a slanted box is a file of the repository.

```mermaid
flowchart LR
  c["Proxy"]
  n1["Application container"]
  n2["TYPO3 demo instance"]
  c -->|"uses"| n1
  n2 -->|"uses"| c
  classDef focus fill:#2F99A4,stroke:#15585E,color:#ffffff
  class c focus
```

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `uses` | [Application container](app-container.md) | `docker/caddy/Caddyfile` | `reverse_proxy web:80 {` | asserted |
