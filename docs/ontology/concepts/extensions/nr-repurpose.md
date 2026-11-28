---
type: Installed Extension
title: "netresearch/nr-repurpose"
description: "The nr-repurpose extension as this instance installs it: Turns a page or PDF into a podcast, diagram and story."
status: draft
timestamp: 2026-11-27
---

# Definition

The package `netresearch/nr-repurpose` (Turns a page or PDF into a podcast, diagram and story) as this instance installs it. `composer.json` names the allowed range and `composer.lock` the version the image contains. The instance requires the package directly, so its version can differ from the version the TYPO3 AI Edition tested.

# Neighbours

Generated from the relation tables by `check-ontology.py --write-diagrams`. A solid arrow is an asserted relation, a dotted arrow a hypothesis; a slanted box is a file of the repository.

```mermaid
flowchart LR
  c["netresearch/nr-repurpose"]
  n1[/"composer.json"/]
  n2["Container image"]
  n3["netresearch/nr-llm"]
  n4["netresearch/nr-vault"]
  n5["Demo account"]
  n6["Extension seed"]
  c -->|"implementedBy"| n1
  c -->|"partOf"| n2
  c -.->|"uses (hypothesis)"| n3
  c -.->|"uses (hypothesis)"| n4
  n5 -->|"uses"| c
  n6 -->|"uses"| c
  classDef focus fill:#2F99A4,stroke:#15585E,color:#ffffff
  class c focus
```

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `partOf` | [Container image](../container-image.md) | `composer.lock` | `"name": "netresearch/nr-repurpose",` | asserted |
| `implementedBy` | `composer.json` | `composer.json` | `"netresearch/nr-repurpose": "^` | asserted |
| `uses` | [netresearch/nr-llm](nr-llm.md) |  |  | hypothesis |
| `uses` | [netresearch/nr-vault](nr-vault.md) |  |  | hypothesis |

# Notes

- The `uses` rows are hypotheses: the `require` block of `netresearch/nr-repurpose` in `composer.lock` names `netresearch/nr-llm` and `netresearch/nr-vault`. The rows are not asserted, because the only literal that names the dependency is its version constraint, which changes with every release of the package and would make the check fail on each lock update.
