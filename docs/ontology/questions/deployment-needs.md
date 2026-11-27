---
type: Competency Question
title: "What a deployment needs"
description: "What must be in place for a deployment to roll out?"
x-nr-query: --needs concepts/deployment
status: draft
timestamp: 2026-11-27
---

# Question

What must be in place before a deployment rolls out?

# How to answer

Follow the relations forwards from the deployment. Run:

```bash
python3 scripts/check-ontology.py docs/ontology --needs concepts/deployment
```

# Answer at the time of writing

```text
concepts/deployment
concepts/container-image
  via concepts/deployment uses concepts/container-image
  test .github/workflows/build.yml
concepts/extension-seed
  via concepts/deployment uses concepts/extension-seed
concepts/demo-instance
  via concepts/deployment uses concepts/demo-instance
concepts/composer-manifest
  via concepts/deployment uses concepts/container-image
  via concepts/container-image derivedFrom concepts/composer-manifest
concepts/extensions/nr-ai-search
  via concepts/deployment uses concepts/container-image
  via concepts/extensions/nr-ai-search partOf concepts/container-image
concepts/extensions/nr-browser-ai
  via concepts/deployment uses concepts/container-image
  via concepts/extensions/nr-browser-ai partOf concepts/container-image
concepts/extensions/nr-landingpage
  via concepts/deployment uses concepts/container-image
  via concepts/extensions/nr-landingpage partOf concepts/container-image
concepts/extensions/nr-llm-compat
  via concepts/deployment uses concepts/container-image
  via concepts/extensions/nr-llm-compat partOf concepts/container-image
concepts/extensions/nr-llm
  via concepts/deployment uses concepts/container-image
  via concepts/extensions/nr-llm partOf concepts/container-image
concepts/extensions/nr-mcp-agent
  via concepts/deployment uses concepts/container-image
  via concepts/extensions/nr-mcp-agent partOf concepts/container-image
concepts/extensions/nr-repurpose
  via concepts/deployment uses concepts/container-image
  via concepts/extensions/nr-repurpose partOf concepts/container-image
concepts/extensions/nr-vault
  via concepts/deployment uses concepts/container-image
  via concepts/extensions/nr-vault partOf concepts/container-image
concepts/extensions/t3-cowriter
  via concepts/deployment uses concepts/container-image
  via concepts/extensions/t3-cowriter partOf concepts/container-image
concepts/app-container
  via concepts/deployment uses concepts/demo-instance
  via concepts/demo-instance uses concepts/app-container
concepts/database
  via concepts/deployment uses concepts/demo-instance
  via concepts/demo-instance uses concepts/database
concepts/cache
  via concepts/deployment uses concepts/demo-instance
  via concepts/demo-instance uses concepts/cache
concepts/proxy
  via concepts/deployment uses concepts/demo-instance
  via concepts/demo-instance uses concepts/proxy
concepts/seed-data
  via concepts/deployment uses concepts/demo-instance
  via concepts/demo-instance uses concepts/database
  via concepts/database uses concepts/seed-data
Scope: only the relations this bundle models; coverage.md names what it leaves out.
```

# Limits

The host, its secrets and the DNS of the instance are outside this repository and not modelled.
