---
type: Installed Extension
title: "netresearch/nr-vault"
description: "The nr-vault extension as this instance installs it: Encrypted secrets that hold the LLM API keys."
status: draft
timestamp: 2026-11-27
---

# Definition

The package `netresearch/nr-vault` (Encrypted secrets that hold the LLM API keys) as this instance installs it. `composer.json` names the allowed range and `composer.lock` the version the image contains. The instance requires the package directly, so its version can differ from the version the TYPO3 AI Edition tested.

# Neighbours

Generated from the relation tables by `check-ontology.py --write-diagrams`. A solid arrow is an asserted relation, a dotted arrow a hypothesis; a slanted box is a file of the repository.

```mermaid
flowchart LR
  c["netresearch/nr-vault"]
  n1[/"composer.json"/]
  n2["Container image"]
  n3["Extension seed"]
  n4["netresearch/nr-ai-search"]
  n5["netresearch/nr-llm"]
  n6["netresearch/nr-repurpose"]
  c -->|"implementedBy"| n1
  c -->|"partOf"| n2
  n3 -->|"uses"| c
  n4 -.->|"uses (hypothesis)"| c
  n5 -.->|"uses (hypothesis)"| c
  n6 -.->|"uses (hypothesis)"| c
  classDef focus fill:#2F99A4,stroke:#15585E,color:#ffffff
  class c focus
```

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `partOf` | [Container image](../container-image.md) | `composer.lock` | `"name": "netresearch/nr-vault",` | asserted |
| `implementedBy` | `composer.json` | `composer.json` | `"netresearch/nr-vault": "^` | asserted |
