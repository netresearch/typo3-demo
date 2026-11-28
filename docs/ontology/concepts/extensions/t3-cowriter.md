---
type: Installed Extension
title: "netresearch/t3-cowriter"
description: "The t3-cowriter extension as this instance installs it: AI writing assistant in CKEditor."
status: draft
timestamp: 2026-11-27
---

# Definition

The package `netresearch/t3-cowriter` (AI writing assistant in CKEditor) as this instance installs it. `composer.json` names the allowed range and `composer.lock` the version the image contains. The instance requires the package directly, so its version can differ from the version the TYPO3 AI Edition tested.

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `partOf` | [Container image](../container-image.md) | `composer.lock` | `"name": "netresearch/t3-cowriter",` | asserted |
| `implementedBy` | `composer.json` | `composer.json` | `"netresearch/t3-cowriter": "^` | asserted |
| `uses` | [netresearch/nr-llm](nr-llm.md) |  |  | hypothesis |

# Notes

- The `uses` rows are hypotheses: the `require` block of `netresearch/t3-cowriter` in `composer.lock` names `netresearch/nr-llm`. The rows are not asserted, because the only literal that names the dependency is its version constraint, which changes with every release of the package and would make the check fail on each lock update.
