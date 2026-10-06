#!/usr/bin/env python3
"""Check that every data/skills/<name>/SKILL.md is seeded intact.

For each skill file the seed (data/seed-extensions.sql) must carry:
  * the body exactly as nr-llm's SkillMarkdownParser produces it (everything after
    the frontmatter block, left-trimmed), as one SQL string literal;
  * the sha256 of that body as body_checksum, which SkillComposer re-computes
    before use and otherwise drops the skill;
  * a source URL pinned to a commit that holds the same file bytes.
The rendered block must also stay inside nr-llm's 24000-byte skill budget.

Standard library only. Exit status 1 on any finding.
"""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SEED = ROOT / "data" / "seed-extensions.sql"
MAX_BYTES = 24000  # SkillComposer::DEFAULT_MAX_BYTES
UNSUPPORTED = [r"\breferences/", r"\bscripts/", r"\bassets/", r"\.(py|sh|js|rb)\b"]
errors: list[str] = []


def fail(msg: str) -> None:
    errors.append(msg)
    print(f"ERROR: {msg}")


def parse(content: str) -> tuple[dict[str, str], str]:
    # Same pattern and trim as SkillMarkdownParser::parse (t3x-nr-llm v0.38.2).
    m = re.match(r"^---\r?\n(.*?)\r?\n---\r?\n?(.*)$", content, re.S)
    if not m:
        raise ValueError("missing YAML front-matter")
    fm: dict[str, str] = {}
    for line in m.group(1).splitlines():
        key, _, val = line.partition(":")
        val = val.strip()
        fm[key.strip()] = json.loads(val) if val.startswith('"') else val
    return fm, m.group(2).lstrip()


def sql_literal(s: str) -> str:
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


def git(*args: str) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True)


def pinned_bytes(sha: str, path: str) -> bytes | None:
    r = git("show", f"{sha}:{path}")
    if r.returncode != 0:
        # A shallow CI checkout does not hold the pinned commit; fetch just that one.
        git("fetch", "--quiet", "--depth=1", "origin", sha)
        r = git("show", f"{sha}:{path}")
    return r.stdout if r.returncode == 0 else None


def main() -> int:
    seed = SEED.read_text(encoding="utf-8")
    skills = sorted((ROOT / "data" / "skills").glob("*/SKILL.md"))
    if not skills:
        fail("no data/skills/*/SKILL.md found")
    for skill in skills:
        rel = skill.relative_to(ROOT).as_posix()
        raw = skill.read_bytes()
        try:
            fm, body = parse(raw.decode("utf-8"))
        except (UnicodeDecodeError, ValueError, json.JSONDecodeError) as e:
            fail(f"{rel}: {e}")
            continue
        name = skill.parent.name
        if fm.get("name") != name:
            fail(f"{rel}: frontmatter name {fm.get('name')!r} differs from directory {name!r}")
        if not fm.get("description"):
            fail(f"{rel}: empty description")
        if "allowed-tools" in fm or "allowed_tools" in fm:
            fail(f"{rel}: allowed-tools would restrict the agent's tools and mark the skill partial")
        if any(re.search(p, body, re.I) for p in UNSUPPORTED):
            fail(f"{rel}: body references scripts/assets, nr-llm marks it partial and strips lines")

        body_bytes = len(body.encode("utf-8"))
        block_bytes = len(f"### Skill: {fm.get('name')}\n{body}\n".encode("utf-8"))
        if block_bytes > MAX_BYTES:
            fail(f"{rel}: composed block is {block_bytes} bytes, budget is {MAX_BYTES}")

        checksum = hashlib.sha256(body.encode("utf-8")).hexdigest()
        if seed.count(sql_literal(body)) != 1:
            fail(f"{rel}: the seed does not carry the body as exactly one SQL literal")
        if seed.count(f"'{checksum}'") < 3:
            fail(f"{rel}: body_checksum {checksum} is missing from the seed (INSERT, UPDATE and verification expected)")

        pins = re.findall(
            rf"raw\.githubusercontent\.com/netresearch/typo3-demo/([0-9a-f]{{40}})/{re.escape(rel)}", seed
        )
        if not pins:
            fail(f"{rel}: the seed has no source URL pinned to a commit of this repository")
        for sha in sorted(set(pins)):
            if (pinned := pinned_bytes(sha, rel)) is None:
                fail(f"{rel}: pinned commit {sha} is not reachable")
            elif pinned != raw:
                fail(f"{rel}: differs from the file at pinned commit {sha}")
        print(f"{rel}: body {body_bytes} bytes, block {block_bytes}/{MAX_BYTES}, sha256 {checksum}, pins {sorted(set(pins))}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
