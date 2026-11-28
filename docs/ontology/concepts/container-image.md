---
type: Instance Component
title: "Container image"
description: "The image ghcr.io/netresearch/typo3-demo: PHP-FPM with nginx, the Composer dependencies and the site package."
status: draft
timestamp: 2026-11-27
---

# Definition

The container image `ghcr.io/netresearch/typo3-demo` holds PHP-FPM with nginx, every Composer dependency in the versions of `composer.lock`, and the site package. The build workflow builds it on every pull request and pushes it only from `main`.

# Neighbours

Generated from the relation tables by `check-ontology.py --write-diagrams`. A solid arrow is an asserted relation, a dotted arrow a hypothesis; a slanted box is a file of the repository.

```mermaid
flowchart LR
  c["Container image"]
  n1["Composer manifest"]
  n2[/"docker/web/Dockerfile"/]
  n3[/".github/workflows/build.yml"/]
  n4["netresearch/nr-ai-search"]
  n5["netresearch/nr-browser-ai"]
  n6["netresearch/nr-landingpage"]
  n7["netresearch/nr-llm"]
  n8["netresearch/nr-llm-compat"]
  n9["netresearch/nr-mcp-agent"]
  n10["netresearch/nr-repurpose"]
  n11["netresearch/nr-vault"]
  n12["netresearch/t3-cowriter"]
  n13["Application container"]
  n14["Deployment"]
  c -->|"derivedFrom"| n1
  c -->|"implementedBy"| n2
  c -->|"verifiedBy"| n3
  n4 -->|"partOf"| c
  n5 -->|"partOf"| c
  n6 -->|"partOf"| c
  n7 -->|"partOf"| c
  n8 -->|"partOf"| c
  n9 -->|"partOf"| c
  n10 -->|"partOf"| c
  n11 -->|"partOf"| c
  n12 -->|"partOf"| c
  n13 -->|"uses"| c
  n14 -->|"uses"| c
  classDef focus fill:#2F99A4,stroke:#15585E,color:#ffffff
  class c focus
```

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `derivedFrom` | [Composer manifest](composer-manifest.md) | `docker/web/Dockerfile` | `AS composer-builder` | asserted |
| `implementedBy` | `docker/web/Dockerfile` | `docker-bake.hcl` | `dockerfile = "docker/web/Dockerfile"` | asserted |
| `verifiedBy` | `.github/workflows/build.yml` | `.github/workflows/build.yml` | `uses: netresearch/.github/.github/workflows/build-container-bake.yml@main` | asserted |
