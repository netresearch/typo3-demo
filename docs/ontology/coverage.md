---
type: Reference
title: "Coverage"
description: "What the demo instance ontology models, what it leaves out, and how to read its statuses."
status: draft
timestamp: 2026-11-27
---

# Scope

The bundle models the parts of the demo instance that its competency questions need: the services, the container image, the Composer manifest, the seed data, the deployment, the demo accounts and the Netresearch AI extensions the instance installs.

# Not modelled

A missing relation means "not modelled", never "not related". Out of scope for now:

- The host, its secrets, DNS and the Caddy certificates.
- The operations workflows (diagnostics, maintenance, remediation, password resets).
- The extensions outside the AI suite (for example passkeys, temporal cache, news) and the TYPO3 core packages.
- The AI extensions of other vendors that `composer.json` requires: `b13/ai-label`, `b13/ai-bots-love-markdown`, `mfd/ai-filemetadata`, `thieleundklose/autotranslate` and `in2code/sitescore`. Some of them reach nr-llm through nr-llm-compat or a patch, so a change of nr-llm can affect them although `--impact` does not list them.
- The content of the database at runtime: configurations, pages and records created on the live instance.

# Statuses

- `asserted`: the evidence text occurs exactly once in the evidence file; the check script confirms this on every run. It does not confirm that the evidence still means the relation.
- `hypothesis`: plausible, without evidence in this repository.
- `status: draft` in the frontmatter marks every file as not yet reviewed by a person.
