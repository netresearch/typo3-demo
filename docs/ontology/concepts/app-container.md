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
| `uses` | [Container image](container-image.md) |  |  | hypothesis |
| `uses` | [Database](database.md) |  |  | hypothesis |
| `uses` | [Cache](cache.md) |  |  | hypothesis |

# Notes

- The three relations are hypotheses: `compose.yml` names the services and their `depends_on` entries, but no single line in it ties one service to the image, the database or the cache uniquely. The `web` service starts with `depends_on` on `db`, `db-init` and `valkey`.
