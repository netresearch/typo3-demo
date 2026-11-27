---
type: Competency Question
title: "An extension gets a new version"
description: "What in the instance follows when an installed extension, for example nr-llm, gets a new version?"
x-nr-query: --impact concepts/extensions/nr-llm
status: draft
generated: {by: claude-code/2.1.332, at: 2026-11-27T21:06:57Z}
---

# Question

An installed extension, for example nr-llm, gets a new version. What in the instance follows, and what must run?

# How to answer

Follow the relations backwards from the installed extension. Run:

```bash
python3 scripts/check-ontology.py docs/ontology --impact concepts/extensions/nr-llm
```

# Answer at the time of writing

```text
concepts/extensions/nr-llm
concepts/demo-account
  via concepts/demo-account uses concepts/extensions/nr-llm
concepts/container-image
  via concepts/extensions/nr-llm partOf concepts/container-image
  test .github/workflows/build.yml
concepts/app-container
  via concepts/extensions/nr-llm partOf concepts/container-image
  via concepts/app-container uses concepts/container-image (hypothesis)
concepts/deployment
  via concepts/extensions/nr-llm partOf concepts/container-image
  via concepts/deployment uses concepts/container-image
concepts/demo-instance
  via concepts/extensions/nr-llm partOf concepts/container-image
  via concepts/app-container uses concepts/container-image (hypothesis)
  via concepts/demo-instance uses concepts/app-container
concepts/proxy
  via concepts/extensions/nr-llm partOf concepts/container-image
  via concepts/app-container uses concepts/container-image (hypothesis)
  via concepts/proxy uses concepts/app-container
Scope: only the relations this bundle models; coverage.md names what it leaves out.
```

# Limits

An extension update on the demo is always a full update: all Netresearch extensions to their newest releases, `composer update` without a package name, the base images, and the superseded dependency-bot pull requests closed (`AGENTS.md`). The merge to `main` builds the image, and "Deploy (Update)" rolls it out. Data in the live database, for example nr-llm configurations, is not part of the image; the seed data covers only a fresh install.
