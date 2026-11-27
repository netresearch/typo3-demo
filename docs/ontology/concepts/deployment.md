---
type: Instance Component
title: "Deployment"
description: "The GitOps path: a merge to main builds the image, and the workflow Deploy (Update) rolls it out on the host."
status: draft
generated: {by: claude-code/2.1.332, at: 2026-11-27T21:06:57Z}
---

# Definition

Deployment is GitOps-driven: a merge to `main` builds and pushes the container image, and the workflow "Deploy (Update)" runs after a successful build and updates the host. Nobody edits the server by hand.

# Relations

| Relation | Target | Evidence file | Evidence text | Status |
|---|---|---|---|---|
| `uses` | [Container image](container-image.md) | `.github/workflows/update.yml` | `workflows: ["Build"]` | asserted |
| `uses` | [TYPO3 demo instance](demo-instance.md) | `.github/workflows/update.yml` | `name: Deploy (Update)` | asserted |
