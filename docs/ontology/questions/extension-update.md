---
type: Competency Question
title: "An extension gets a new version"
description: "What in the instance follows when an installed extension, for example nr-llm, gets a new version?"
x-nr-query: --impact concepts/extensions/nr-llm
status: draft
timestamp: 2026-11-27
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
concepts/extension-seed
  via concepts/extension-seed uses concepts/extensions/nr-llm
concepts/extensions/nr-ai-search
  via concepts/extensions/nr-ai-search uses concepts/extensions/nr-llm (hypothesis)
concepts/extensions/nr-landingpage
  via concepts/extensions/nr-landingpage uses concepts/extensions/nr-llm (hypothesis)
concepts/extensions/nr-llm-compat
  via concepts/extensions/nr-llm-compat uses concepts/extensions/nr-llm (hypothesis)
concepts/container-image
  via concepts/extensions/nr-llm partOf concepts/container-image
  test .github/workflows/build.yml
concepts/extensions/nr-mcp-agent
  via concepts/extensions/nr-mcp-agent uses concepts/extensions/nr-llm (hypothesis)
concepts/extensions/nr-repurpose
  via concepts/extensions/nr-repurpose uses concepts/extensions/nr-llm (hypothesis)
concepts/extensions/t3-cowriter
  via concepts/extensions/t3-cowriter uses concepts/extensions/nr-llm (hypothesis)
concepts/deployment
  via concepts/extension-seed uses concepts/extensions/nr-llm
  via concepts/deployment uses concepts/extension-seed
concepts/app-container
  via concepts/extensions/nr-llm partOf concepts/container-image
  via concepts/app-container uses concepts/container-image
concepts/demo-instance
  via concepts/extensions/nr-llm partOf concepts/container-image
  via concepts/app-container uses concepts/container-image
  via concepts/demo-instance uses concepts/app-container
concepts/proxy
  via concepts/extensions/nr-llm partOf concepts/container-image
  via concepts/app-container uses concepts/container-image
  via concepts/proxy uses concepts/app-container
Scope: only the relations this bundle models; coverage.md names what it leaves out.
```

# Limits

An extension update on the demo is always a full update: all Netresearch extensions to their newest releases, `composer update` without a package name, the base images, and the superseded dependency-bot pull requests closed (`AGENTS.md`). The merge to `main` builds the image, and "Deploy (Update)" rolls it out. Data in the live database is not part of the image. The seed data (`data/db.sql.gz`) enters only an empty database, but the extension seed (`data/seed-extensions.sql`) is applied again by `make update` on every deploy, so a change to the nr-llm records there reaches the live instance with the next merge.
