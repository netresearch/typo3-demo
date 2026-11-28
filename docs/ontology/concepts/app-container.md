---
type: Instance Component
title: "Application container"
description: "The web, worker and scheduler services, all started from the one image of this repository."
status: draft
timestamp: 2026-11-27
---

# Definition

The application containers are the services `web`, `worker`, `chat-worker`, `chat-cleanup`, `social-publish`, `vector-compact`, `scheduler` and `alt-text-batch`. All of them start from the container image of this repository with different commands.

# Neighbours

Generated from the relation tables by `check-ontology.py --write-diagrams`. A solid arrow is an asserted relation, a dotted arrow a hypothesis; a slanted box is a file of the repository.

```mermaid
flowchart LR
  c["Application container"]
  n1["Cache"]
  n2["Container image"]
  n3["Database"]
  n4["TYPO3 demo instance"]
  n5["Proxy"]
  c -.->|"uses (hypothesis)"| n1
  c -->|"uses"| n2
  c -.->|"uses (hypothesis)"| n3
  n4 -->|"uses"| c
  n5 -->|"uses"| c
  classDef focus fill:#2F99A4,stroke:#15585E,color:#ffffff
  class c focus
```

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `uses` | [Container image](container-image.md) | `compose.yml` | `dockerfile: docker/web/Dockerfile` | asserted |
| `uses` | [Database](database.md) |  |  | hypothesis |
| `uses` | [Cache](cache.md) |  |  | hypothesis |

# Notes

- The relations to the database and the cache are hypotheses: `compose.yml` names the services and their `depends_on` entries, but no single line in it ties one service to the database or the cache uniquely. All application services start from the image that `compose.yml` builds from `docker/web/Dockerfile`.
