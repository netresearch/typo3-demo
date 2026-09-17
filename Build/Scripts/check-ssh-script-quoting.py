#!/usr/bin/env python3
"""Refuse an apostrophe inside a multi-line single-quoted `sh -c '...'`.

This exists because it already happened. A comment reading "grep's own status,
not the pipeline's" went into the body of a `docker compose exec -T web sh -c
'...'` block in instance-remediation.yml. The first apostrophe closed the
string, everything after it was reinterpreted, and the remote shell died with

    syntax error: unexpected end of file (expecting "done")

after the workflow had been merged and dispatched against the instance.

`bash -n` on the workflow's own script does NOT catch it: the two apostrophes
balance, so the outer quoting survives and only the inner block is wrecked.
The check that catches it is this one - read the inner block and look at it.

It works on the RAW file rather than on a yq projection, and deliberately so.
The first version of this script asked yq for `.jobs[].steps[].with.script`,
which missed a `sh -c` inside a plain `run:` step, and used a yq expression
this yq rejects besides - so it examined nothing and reported clean on the very
apostrophe it was written to catch. The hazard is textual; the check is too.

A single-line `sh -c '...'` is left alone: its closing quote is on the same
line, so an apostrophe inside it is a syntax error the YAML or the shell
catches immediately rather than a silent reinterpretation.

Usage: check-ssh-script-quoting.py [workflow.yml ...]   (default: all of them)
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

OPENER = "sh -c '"


def multiline_blocks(text: str) -> list[tuple[int, int, list[str]]]:
    """Each multi-line `sh -c '` body as (first_line, last_line, lines)."""
    lines = text.splitlines()
    out: list[tuple[int, int, list[str]]] = []
    i = 0
    while i < len(lines):
        col = lines[i].find(OPENER)
        if col == -1:
            i += 1
            continue

        rest = lines[i][col + len(OPENER) :]
        if "'" in rest:  # opener and closer on one line - not this hazard
            i += 1
            continue

        indent = len(lines[i]) - len(lines[i].lstrip())
        for j in range(i + 1, len(lines)):
            stripped = lines[j].strip()
            # The closer is a line that is just the quote, optionally with a
            # trailing operator such as `|| echo ...` or a continuation.
            if stripped == "'" or stripped.startswith("' ") or stripped.startswith("'|"):
                out.append((i + 1, j + 1, lines[i + 1 : j]))
                i = j
                break
        else:
            out.append((i + 1, len(lines), lines[i + 1 :]))
            break
        i += 1
    return out


def main(argv: list[str]) -> int:
    root = Path(__file__).resolve().parents[2]
    paths = [Path(a) for a in argv[1:]] or sorted((root / ".github/workflows").glob("*.yml"))

    failures = 0
    checked = 0
    for path in paths:
        text = path.read_text(encoding="utf-8")
        for first, last, body in multiline_blocks(text):
            checked += 1
            where = f"{path.name}:{first}-{last}"

            offenders = [first + n for n, line in enumerate(body, 1) if "'" in line]
            if offenders:
                print(f"::error file={path},line={offenders[0]}::apostrophe inside a multi-line sh -c block ({where}).")
                print("  One apostrophe closes the single-quoted sh -c; a pair of them balances,")
                print("  so bash -n on the outer script still passes and only the inner block breaks.")
                failures += 1
                continue

            # The inner script was never linted before; the outer one was.
            script = "\n".join(body)
            check = subprocess.run(["sh", "-n"], input=script, capture_output=True, text=True)
            if check.returncode != 0:
                print(f"::error file={path},line={first}::the inner sh -c script does not parse ({where}):")
                print(f"  {check.stderr.strip()}")
                failures += 1

    if failures:
        return 1
    print(f"{len(paths)} workflow file(s), {checked} multi-line sh -c block(s): no apostrophes, all parse")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
