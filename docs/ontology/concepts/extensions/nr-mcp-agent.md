---
type: Installed Extension
title: "netresearch/nr-mcp-agent"
description: "The nr-mcp-agent extension as this instance installs it: Tool-using AI chat in the backend."
status: draft
timestamp: 2026-11-27
---

# Definition

The package `netresearch/nr-mcp-agent` (Tool-using AI chat in the backend) as this instance installs it. `composer.json` names the allowed range and `composer.lock` the version the image contains. The instance requires the package directly, so its version can differ from the version the TYPO3 AI Edition tested.

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `partOf` | [Container image](../container-image.md) | `composer.lock` | `"name": "netresearch/nr-mcp-agent",` | asserted |
| `implementedBy` | `composer.json` | `composer.json` | `"netresearch/nr-mcp-agent": "^` | asserted |
| `uses` | [netresearch/nr-llm](nr-llm.md) |  |  | hypothesis |

# Notes

- The `uses` rows are hypotheses: the `require` block of `netresearch/nr-mcp-agent` in `composer.lock` names `netresearch/nr-llm`, but the same constraint text occurs in several packages there, so no literal occurs exactly once.
