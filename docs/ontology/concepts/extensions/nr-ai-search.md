---
type: Installed Extension
title: "netresearch/nr-ai-search"
description: "The nr-ai-search extension as this instance installs it: Vector search and RAG chat over the site content."
status: draft
timestamp: 2026-11-27
---

# Definition

The package `netresearch/nr-ai-search` (Vector search and RAG chat over the site content) as this instance installs it. `composer.json` names the allowed range and `composer.lock` the version the image contains. The package is not a member of the TYPO3 AI Edition.

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `partOf` | [Container image](../container-image.md) | `composer.lock` | `"name": "netresearch/nr-ai-search",` | asserted |
| `implementedBy` | `composer.json` | `composer.json` | `"netresearch/nr-ai-search": "^` | asserted |
| `uses` | [netresearch/nr-llm](nr-llm.md) |  |  | hypothesis |
| `uses` | [netresearch/nr-vault](nr-vault.md) |  |  | hypothesis |

# Notes

- The `uses` rows are hypotheses: the `require` block of `netresearch/nr-ai-search` in `composer.lock` names `netresearch/nr-llm` and `netresearch/nr-vault`, but the same constraint text occurs in several packages there, so no literal occurs exactly once.
