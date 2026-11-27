---
type: Instance
title: "TYPO3 demo instance"
description: "The live TYPO3 14 showcase of the Netresearch extensions at typo3-demo.netresearch.de."
status: draft
generated: {by: claude-code/2.1.332, at: 2026-11-27T21:06:57Z}
---

# Definition

The demo instance is the live, disposable TYPO3 14 showcase of the Netresearch extension suite at https://typo3-demo.netresearch.de/. It runs the same container stack in local development and in production.

# Not to be confused with

- The TYPO3 AI Edition. The edition is a Composer package of tested versions; this instance requires the extensions individually.

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `uses` | [Application container](app-container.md) | `compose.yml` | `dockerfile: docker/web/Dockerfile` | asserted |
| `uses` | [Database](database.md) | `compose.yml` | `- typo3-db-v2:/var/lib/mysql` | asserted |
| `uses` | [Cache](cache.md) | `compose.yml` | `image: valkey/valkey:9-alpine@sha256:` | asserted |
| `uses` | [Proxy](proxy.md) | `compose.yml` | `image: dhi.io/caddy:2` | asserted |
| `implementedBy` | `compose.yml` | `README.md` | `A reproducible, disposable TYPO3 14 showcase for the Netresearch extension suite.` | asserted |
