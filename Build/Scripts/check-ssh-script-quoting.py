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

Usage: check-ssh-script-quoting.py [workflow.yml ...]   (default: every .yml and .yaml)
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

OPENER = "sh -c '"

# A `{n}` repetition count in a regex, which POSIX bounds at 255.
DUP_COUNT = re.compile(r"\{(\d+)\}")


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


def workflow_dir() -> Path:
    return (Path(__file__).resolve().parents[2] / ".github/workflows").resolve()


def selected(argv: list[str]) -> list[Path]:
    """The workflow files to check, and nothing else.

    An argument is resolved and required to sit inside .github/workflows. This
    script reads whatever it is handed, so without the bound a caller could
    point it at any file on the runner - which is what SonarCloud flags as a
    path traversal, correctly. Bounding it also states the contract: this
    checks workflows, not arbitrary YAML.
    """
    root = workflow_dir()
    if not argv:
        # Both extensions: GitHub Actions reads .yml AND .yaml, so globbing one
        # of them lets a workflow written with the other bypass this check
        # silently - a gate that fires for nobody, which is the shape this file
        # exists to catch elsewhere.
        return sorted(p for ext in ("*.yml", "*.yaml") for p in root.glob(ext))

    chosen: list[Path] = []
    for arg in argv:
        candidate = (root / Path(arg).name).resolve()
        if candidate.parent != root or not candidate.is_file():
            raise SystemExit(f"refusing {arg!r}: only files inside {root} are checked")
        chosen.append(candidate)
    return chosen


def main(argv: list[str]) -> int:
    paths = selected(argv[1:])

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

            # A repetition count above the POSIX RE_DUP_MAX of 255 parses
            # fine and then fails at run time on BusyBox, which is what the
            # web image ships. `sed -E "s/^(.{400}).*/\\1/"` came back as
            # "Invalid contents of {}" and the diagnostic printed file names
            # with nothing under them. `sh -n` cannot see this - it is a
            # regex-library bound, not syntax - so it is checked here.
            for n, line in enumerate(body, 1):
                # Comments are prose and may name the bound they warn about;
                # only what the shell executes is checked.
                if line.lstrip().startswith("#"):
                    continue
                for count in DUP_COUNT.findall(line):
                    if int(count) > 255:
                        print(f"::error file={path},line={first + n}::regex repetition {{{count}}} exceeds the POSIX RE_DUP_MAX of 255.")
                        print("  BusyBox sed rejects it at run time with \"Invalid contents of {}\"; use cut, or split the match.")
                        failures += 1

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
