---
type: Competency Question
title: "What a deployment needs"
description: "What must be in place for a deployment to roll out?"
x-nr-query: --needs concepts/deployment
status: draft
generated: {by: claude-code/2.1.332, at: 2026-11-27T21:06:57Z}
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
concepts/demo-instance
  via concepts/deployment uses concepts/demo-instance
concepts/composer-manifest
  via concepts/deployment uses concepts/container-image
  via concepts/container-image derivedFrom concepts/composer-manifest
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
