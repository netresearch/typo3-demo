---
okf_version: "0.3"
title: TYPO3 demo instance ontology
description: The parts of the TYPO3 demo instance and the extensions it installs, with typed relations checked against this repository, for questions such as what an extension update requires.
license: GPL-2.0-or-later
---

# TYPO3 demo instance ontology

This bundle describes one instance, not a product: the demo at https://typo3-demo.netresearch.de/, its services, its container image, its seed data, its deployment and the AI extensions it installs. Every relation names the file in this repository that shows it. The concepts inside an extension belong to the bundle of that extension, and the product concepts of the TYPO3 AI Edition to the bundle of the edition.

This bundle follows the Open Knowledge Format 0.3 (https://okf.md): one Markdown file per concept, with a YAML frontmatter block that names its `type`.

# Use it

Run the check from the repository root. The workflow `Ontology` runs the first command on every pull request.

```bash
python3 scripts/check-ontology.py docs/ontology                                  # check the bundle against the code
python3 scripts/check-ontology.py docs/ontology --impact concepts/extensions/nr-llm     # what a change to it can affect
python3 scripts/check-ontology.py docs/ontology --needs concepts/deployment       # what it depends on
```

The check fails when an asserted relation loses its evidence in the code. Fix the relation in the same change as the code.

# Contents

* [Concepts](concepts/index.md) - The parts of the instance and the extensions it installs, one file each
* [Relations](relations/index.md) - The relation vocabulary: what each relation means and in which direction a change propagates
* [Competency questions](questions/index.md) - The questions this bundle is built to answer, with the answer at the time of writing
* [Coverage](coverage.md) - What this bundle models, what it leaves out, and how to read its statuses

# Format of a concept

Every concept file has the sections `# Definition`, an optional `# Not to be confused with`, `# Relations` and optional `# Notes`. The relations table has five columns:

| Column | Content |
|---|---|
| Relation | A relation of the vocabulary in `relations/` |
| Target | A link to a concept, a path in this repository in backticks, or an external URL |
| Evidence file | The file, relative to the repository root, that shows the relation |
| Evidence text | A literal from one line of that file; the check requires it to be present |
| Status | `asserted`: read in the code and checked by the script. `hypothesis`: not yet backed by evidence |

The relation vocabulary is the same in every Netresearch bundle. Its canonical copy, and the relations between repositories, are kept in software-factory/ontology, an internal repository of Netresearch.
