---
type: Instance Component
title: "Deployment"
description: "The GitOps path: a merge to main builds the image, and the workflow Deploy (Update) rolls it out on the host."
status: draft
timestamp: 2026-11-27
---

# Definition

Deployment is GitOps-driven: a merge to `main` builds and pushes the container image, and the workflow "Deploy (Update)" runs after a successful build and updates the host. Nobody edits the server by hand.

# Neighbours

Generated from the relation tables by `check-ontology.py --write-diagrams`. A solid arrow is an asserted relation, a dotted arrow a hypothesis; a slanted box is a file of the repository.

```mermaid
flowchart LR
  c["Deployment"]
  n1["Container image"]
  n2["TYPO3 demo instance"]
  n3["Extension seed"]
  c -->|"uses"| n1
  c -->|"uses"| n2
  c -->|"uses"| n3
  classDef focus fill:#2F99A4,stroke:#15585E,color:#ffffff
  class c focus
```

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `uses` | [Container image](container-image.md) | `.github/workflows/update.yml` | `workflows: ["Build"]` | asserted |
| `uses` | [Extension seed](extension-seed.md) | `.github/workflows/update.yml` | `docker compose version make update` | asserted |
| `uses` | [TYPO3 demo instance](demo-instance.md) | `.github/workflows/update.yml` | `name: Deploy (Update)` | asserted |
