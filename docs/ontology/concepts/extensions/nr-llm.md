---
type: Installed Extension
title: "netresearch/nr-llm"
description: "The nr-llm extension as this instance installs it: LLM foundation: providers, models, configurations, chat, embeddings."
status: draft
timestamp: 2026-11-27
---

# Definition

The package `netresearch/nr-llm` (LLM foundation: providers, models, configurations, chat, embeddings) as this instance installs it. `composer.json` names the allowed range and `composer.lock` the version the image contains. The instance requires the package directly, so its version can differ from the version the TYPO3 AI Edition tested.

# Neighbours

Generated from the relation tables by `check-ontology.py --write-diagrams`. A solid arrow is an asserted relation, a dotted arrow a hypothesis; a slanted box is a file of the repository.

```mermaid
flowchart LR
  c["netresearch/nr-llm"]
  n1[/"composer.json"/]
  n2["Container image"]
  n3["netresearch/nr-vault"]
  n4["Demo account"]
  n5["Extension seed"]
  n6["netresearch/nr-ai-search"]
  n7["netresearch/nr-landingpage"]
  n8["netresearch/nr-llm-compat"]
  n9["netresearch/nr-mcp-agent"]
  n10["netresearch/nr-repurpose"]
  n11["netresearch/t3-cowriter"]
  c -->|"implementedBy"| n1
  c -->|"partOf"| n2
  c -.->|"uses (hypothesis)"| n3
  n4 -->|"uses"| c
  n5 -->|"uses"| c
  n6 -.->|"uses (hypothesis)"| c
  n7 -.->|"uses (hypothesis)"| c
  n8 -.->|"uses (hypothesis)"| c
  n9 -.->|"uses (hypothesis)"| c
  n10 -.->|"uses (hypothesis)"| c
  n11 -.->|"uses (hypothesis)"| c
  classDef focus fill:#2F99A4,stroke:#15585E,color:#ffffff
  class c focus
```

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `partOf` | [Container image](../container-image.md) | `composer.lock` | `"name": "netresearch/nr-llm",` | asserted |
| `implementedBy` | `composer.json` | `composer.json` | `"netresearch/nr-llm": "^` | asserted |
| `uses` | [netresearch/nr-vault](nr-vault.md) |  |  | hypothesis |

# Notes

- The `uses` rows are hypotheses: the `require` block of `netresearch/nr-llm` in `composer.lock` names `netresearch/nr-vault`, but the same constraint text occurs in several packages there, so no literal occurs exactly once.
