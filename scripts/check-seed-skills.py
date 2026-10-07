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


def check_frontmatter(rel: str, name: str, fm: dict[str, str], body: str) -> None:
    if fm.get("name") != name:
        fail(f"{rel}: frontmatter name {fm.get('name')!r} differs from directory {name!r}")
    if not fm.get("description"):
        fail(f"{rel}: empty description")
    if "allowed-tools" in fm or "allowed_tools" in fm:
        fail(f"{rel}: allowed-tools would restrict the agent's tools and mark the skill partial")
    if any(re.search(p, body, re.I) for p in UNSUPPORTED):
        fail(f"{rel}: body references scripts/assets, nr-llm marks it partial and strips lines")


def check_pins(rel: str, raw: bytes, seed: str) -> list[str]:
    pins = sorted(
        set(
            re.findall(
                rf"raw\.githubusercontent\.com/netresearch/typo3-demo/([0-9a-f]{{40}})/{re.escape(rel)}", seed
            )
        )
    )
    if not pins:
        fail(f"{rel}: the seed has no source URL pinned to a commit of this repository")
    for sha in pins:
        pinned = pinned_bytes(sha, rel)
        if pinned is None:
            fail(f"{rel}: pinned commit {sha} is not reachable")
        elif pinned != raw:
            fail(f"{rel}: differs from the file at pinned commit {sha}")
    return pins


def check_skill(skill: Path, seed: str) -> None:
    rel = skill.relative_to(ROOT).as_posix()
    raw = skill.read_bytes()
    try:
        fm, body = parse(raw.decode("utf-8"))
    except ValueError as e:  # UnicodeDecodeError and json.JSONDecodeError are ValueErrors
        fail(f"{rel}: {e}")
        return
    check_frontmatter(rel, skill.parent.name, fm, body)

    body_bytes = len(body.encode("utf-8"))
    block_bytes = len(f"### Skill: {fm.get('name')}\n{body}\n".encode("utf-8"))
    if block_bytes > MAX_BYTES:
        fail(f"{rel}: composed block is {block_bytes} bytes, budget is {MAX_BYTES}")

    checksum = hashlib.sha256(body.encode("utf-8")).hexdigest()
    if seed.count(sql_literal(body)) != 1:
        fail(f"{rel}: the seed does not carry the body as exactly one SQL literal")
    if seed.count(f"'{checksum}'") < 3:
        fail(f"{rel}: body_checksum {checksum} is missing from the seed (INSERT, UPDATE and verification expected)")

    pins = check_pins(rel, raw, seed)
    print(f"{rel}: body {body_bytes} bytes, block {block_bytes}/{MAX_BYTES}, sha256 {checksum}, pins {pins}")


SOURCE_ROW = re.compile(r"\((\d+), 0, '[^']*', 'single_file', 'https://raw\.githubusercontent\.com/[^/]+/[^/]+/[^/]+/([^']+)'")
SKILL_ROW = re.compile(r"\((\d+), 0, (\d+), '([^']*)', '[^']*', '")
UPDATE_IDENTIFIER = re.compile(r"identifier = '([^']*)'")
UPDATE_TARGET = re.compile(r"WHERE uid = (\d+) AND source = (\d+)$")


def skill_updates(seed: str) -> list[tuple[int, int, str]]:
    # Each re-assert statement is cut out first, so the patterns below never scan
    # across statement boundaries.
    found = []
    for part in seed.split("UPDATE tx_nrllm_skill SET ")[1:]:
        statement = part.split(";", 1)[0]
        ident, target = UPDATE_IDENTIFIER.search(statement), UPDATE_TARGET.search(statement)
        if ident and target:
            found.append((int(target.group(1)), int(target.group(2)), ident.group(1)))
    return found


def check_identifiers(seed: str) -> None:
    # SkillSyncService (t3x-nr-llm v0.38.2, sync()) keys a synced skill as
    # "<source uid>:<path>" and looks it up by exactly that. A seeded row with any
    # other identifier is not found by the next sync, which adds a duplicate.
    paths = {int(uid): path for uid, path in SOURCE_ROW.findall(seed)}
    rows = [(int(u), int(s), i, "INSERT") for u, s, i in SKILL_ROW.findall(seed)]
    rows += [(u, s, i, "UPDATE") for u, s, i in skill_updates(seed)]
    if not paths or not rows:
        fail("no seeded single_file source or skill row found; the identifier check matched nothing")
    for uid, source, identifier, where in rows:
        if source not in paths:
            fail(f"tx_nrllm_skill {uid} ({where}): source {source} is not a seeded single_file source")
            continue
        expected = f"{source}:{paths[source]}"
        if identifier != expected:
            fail(f"tx_nrllm_skill {uid} ({where}): identifier {identifier!r}, a sync looks up {expected!r}")
    print(f"identifiers: {len(rows)} seeded skill statements checked against <source>:<path>")


def main() -> int:
    seed = SEED.read_text(encoding="utf-8")
    skills = sorted((ROOT / "data" / "skills").glob("*/SKILL.md"))
    if not skills:
        fail("no data/skills/*/SKILL.md found")
    for skill in skills:
        check_skill(skill, seed)
    check_identifiers(seed)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
