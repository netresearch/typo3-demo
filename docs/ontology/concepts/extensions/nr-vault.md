---
type: Installed Extension
title: "netresearch/nr-vault"
description: "The nr-vault extension as this instance installs it: Encrypted secrets that hold the LLM API keys."
status: draft
timestamp: 2026-11-27
---

# Definition

The package `netresearch/nr-vault` (Encrypted secrets that hold the LLM API keys) as this instance installs it. `composer.json` names the allowed range and `composer.lock` the version the image contains. The instance requires the package directly, so its version can differ from the version the TYPO3 AI Edition tested.

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `partOf` | [Container image](../container-image.md) | `composer.lock` | `"name": "netresearch/nr-vault",` | asserted |
| `implementedBy` | `composer.json` | `composer.json` | `"netresearch/nr-vault": "^` | asserted |
