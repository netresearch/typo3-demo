---
type: Installed Extension
title: "netresearch/nr-llm-compat"
description: "The nr-llm-compat extension as this instance installs it: Routes LLM calls of third-party AI extensions through nr-llm."
status: draft
timestamp: 2026-11-27
---

# Definition

The package `netresearch/nr-llm-compat` (Routes LLM calls of third-party AI extensions through nr-llm) as this instance installs it. `composer.json` names the allowed range and `composer.lock` the version the image contains. The instance requires the package directly, so its version can differ from the range the TYPO3 AI Edition tested it in as a suggested member.

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `partOf` | [Container image](../container-image.md) | `composer.lock` | `"name": "netresearch/nr-llm-compat",` | asserted |
| `implementedBy` | `composer.json` | `composer.json` | `"netresearch/nr-llm-compat": "^` | asserted |
| `uses` | [netresearch/nr-llm](nr-llm.md) |  |  | hypothesis |

# Notes

- The `uses` rows are hypotheses: the `require` block of `netresearch/nr-llm-compat` in `composer.lock` names `netresearch/nr-llm`, but the same constraint text occurs in several packages there, so no literal occurs exactly once.
