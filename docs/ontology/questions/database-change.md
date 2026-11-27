---
type: Competency Question
title: "The database changes"
description: "What depends on the database service, for example when its image changes?"
x-nr-query: --impact concepts/database
status: draft
generated: {by: claude-code/2.1.332, at: 2026-11-27T21:06:57Z}
---

# Question

The database image changes, or the database is reset. What is affected?

# How to answer

Follow the relations backwards from the database. Run:

```bash
python3 scripts/check-ontology.py docs/ontology --impact concepts/database
```

# Answer at the time of writing

```text
concepts/database
concepts/app-container
  via concepts/app-container uses concepts/database (hypothesis)
concepts/demo-instance
  via concepts/demo-instance uses concepts/database
concepts/proxy
  via concepts/app-container uses concepts/database (hypothesis)
  via concepts/proxy uses concepts/app-container
concepts/deployment
  via concepts/demo-instance uses concepts/database
  via concepts/deployment uses concepts/demo-instance
Scope: only the relations this bundle models; coverage.md names what it leaves out.
```

# Limits

A reset imports the seed data again, so content created on the live instance since the last export is lost unless it was exported first.
