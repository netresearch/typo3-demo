---
type: Instance Component
title: "Application container"
description: "The web, worker and scheduler services, all started from the one image of this repository."
status: draft
generated: {by: claude-code/2.1.332, at: 2026-11-27T21:06:57Z}
---

# Definition

The application containers are the services `web`, `worker`, `chat-worker`, `chat-cleanup`, `social-publish`, `vector-compact`, `scheduler` and `alt-text-batch`. All of them start from the container image of this repository with different commands.

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `uses` | [Container image](container-image.md) | `compose.yml` | `  worker:` | asserted |
| `uses` | [Database](database.md) | `compose.yml` | `  chat-worker:` | asserted |
| `uses` | [Cache](cache.md) | `compose.yml` | `  vector-compact:` | asserted |

# Notes

- The evidence texts only prove that the services exist in `compose.yml`; the image reference `ghcr.io/netresearch/typo3-demo` repeats for every service, so it cannot serve as a unique literal.
