#!/usr/bin/env python3
"""Fail on HTML entities that were escaped twice in the seed SQL.

The html content elements carry hand-written markup that TYPO3 outputs as is,
so `&amp;mdash;` in a bodytext reaches the page as the literal text "&mdash;"
instead of a dash (tt_content 9504, 9506 and 9515, NEXT-187). An escaped
ampersand followed by an entity name and a semicolon is never wanted here: a
real ampersand in the markup is `&amp;` followed by a space or text.

Standard library only. Exit status 1 on any finding.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOUBLE_ESCAPED = re.compile(r"&amp;(#[0-9]+|#x[0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);")


def main() -> int:
    files = sorted((ROOT / "data").glob("*.sql"))
    if not files:
        print("ERROR: no data/*.sql found")
        return 1
    findings = 0
    for path in files:
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            for match in DOUBLE_ESCAPED.finditer(line):
                findings += 1
                print(f"ERROR: {path.relative_to(ROOT)}:{number}: double-escaped entity {match.group(0)!r}")
    print(f"{len(files)} seed files checked, {findings} double-escaped entities")
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
