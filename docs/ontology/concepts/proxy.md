---
type: Instance Component
title: "Proxy"
description: "Caddy, the HTTPS front of the instance."
status: draft
timestamp: 2026-11-27
---

# Definition

The proxy is Caddy (`dhi.io/caddy`), which terminates HTTPS and forwards requests to the web container.

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `uses` | [Application container](app-container.md) | `docker/caddy/Caddyfile` | `reverse_proxy web:80 {` | asserted |
