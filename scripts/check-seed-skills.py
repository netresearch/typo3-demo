#!/usr/bin/env python3
"""Check that every data/skills/<name>/SKILL.md is seeded intact.

For each skill file the seed (data/seed-extensions.sql) must carry:
  * the body exactly as nr-llm's SkillMarkdownParser produces it (everything after
    the frontmatter block, left-trimmed), as one SQL string literal;
  * the sha256 of that body as body_checksum, which SkillComposer re-computes
    before use and otherwise drops the skill;
  * a source URL pinned to a commit that holds the same file bytes.
The rendered block must also stay inside nr-llm's 24000-byte skill budget.

A process skill (frontmatter `process: true`, nr-llm ADR-214) is seeded on a
source of type 'backend' instead, with no pin. For it the seed must carry the
body literal assigned to the variable its rows use, the identifier
'<source uid>:<name>', process = 1, and the frontmatter's allowed-tools as the
sorted JSON list in the INSERT, the re-assert and the tool lines of the digest:
an invoked process skill without a declaration runs with no tool at all.

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


def is_process(fm: dict[str, str]) -> bool:
    return fm.get("process") == "true"


def declared_tools(fm: dict[str, str]) -> list[str]:
    # The string form SkillFrontmatter accepts ("a, b" or "a b"), de-duplicated and
    # sorted as SkillVersionDigest::normaliseTools() sorts it.
    raw = fm.get("allowed-tools", "")
    return sorted({t for t in re.split(r"[\s,]+", raw.strip()) if t})


def check_frontmatter(rel: str, name: str, fm: dict[str, str], body: str) -> None:
    if fm.get("name") != name:
        fail(f"{rel}: frontmatter name {fm.get('name')!r} differs from directory {name!r}")
    if not fm.get("description"):
        fail(f"{rel}: empty description")
    if is_process(fm):
        if not declared_tools(fm):
            fail(f"{rel}: a process skill without allowed-tools runs with no tool at all")
    elif "allowed-tools" in fm or "allowed_tools" in fm:
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

    if is_process(fm):
        check_backend_skill(rel, fm, body, checksum, seed)
        print(f"{rel}: process skill, body {body_bytes} bytes, sha256 {checksum}, tools {len(declared_tools(fm))}")
        return

    if seed.count(f"'{checksum}'") < 3:
        fail(f"{rel}: body_checksum {checksum} is missing from the seed (INSERT, UPDATE and verification expected)")

    pins = check_pins(rel, raw, seed)
    print(f"{rel}: body {body_bytes} bytes, block {block_bytes}/{MAX_BYTES}, sha256 {checksum}, pins {pins}")


# A process skill's statements sit inside prepared-statement strings, where every
# quote is doubled.
BACKEND_SOURCE_ROW = re.compile(r"VALUES \((\d+), 0, ''[^']*'', ''backend'',")
BACKEND_SKILL_ROW = re.compile(
    r"\((\d+), 0, (\d+), ''([^']*)'', ''([^']*)'', ''(?:[^']|'')*'',\s*"
    r"@(\w+), ''([0-9a-f]{64})'', '''', ''full'', ''(\[[^']*\])'', 1, ''first_party'', 1,"
)


def check_backend_skill(rel: str, fm: dict[str, str], body: str, checksum: str, seed: str) -> None:
    name = fm["name"]
    tools = declared_tools(fm)
    tools_json = json.dumps(tools, separators=(",", ":"))
    sources = {int(uid) for uid in BACKEND_SOURCE_ROW.findall(seed)}
    rows = [r for r in BACKEND_SKILL_ROW.findall(seed) if r[3] == name]
    if len(rows) != 1:
        fail(f"{rel}: expected one process-skill INSERT named {name!r} in the seed, found {len(rows)}")
        return
    uid, source, identifier, _, variable, row_checksum, row_tools = rows[0]
    if int(source) not in sources:
        fail(f"{rel}: tx_nrllm_skill {uid} is on source {source}, which is not a seeded 'backend' source")
    if identifier != f"{source}:{name}":
        # nr_mcp_agent's dashboard resolves the slug against '<source uid>:<slug>'.
        fail(f"{rel}: identifier {identifier!r}, the dashboard looks up {source + ':' + name!r}")
    if row_checksum != checksum:
        fail(f"{rel}: INSERT body_checksum {row_checksum} differs from sha256 of the body {checksum}")
    if row_tools != tools_json:
        fail(f"{rel}: INSERT allowed_tools {row_tools} differs from the frontmatter {tools_json}")
    if f"SET @{variable} = {sql_literal(body)};" not in seed:
        fail(f"{rel}: @{variable}, which the INSERT uses, is not set to the body")

    statements = [part.split("PREPARE seed_stmt", 1)[0] for part in seed.split("SET @seed_sql = ")[1:]]
    target = f"WHERE uid = {uid} AND source = {source}"
    reassert = [s for s in statements if re.match(r"IF\(@\w+, '\s*UPDATE tx_nrllm_skill SET name", s) and target in s]
    if len(reassert) != 1:
        fail(f"{rel}: expected one re-assert UPDATE for tx_nrllm_skill {uid}, found {len(reassert)}")
    else:
        for expected in (f"body = @{variable},", f"body_checksum = ''{checksum}''", f"allowed_tools = ''{tools_json}''",
                         "process = 1,", f"identifier = ''{identifier}''"):
            if expected not in reassert[0]:
                fail(f"{rel}: the re-assert UPDATE of tx_nrllm_skill {uid} does not set {expected}")
    digest = [s for s in statements if "SET version_digest" in s and target in s]
    if len(digest) != 1:
        fail(f"{rel}: expected one digest UPDATE for tx_nrllm_skill {uid}, found {len(digest)}")
        return
    lines = re.findall(r"''tool=(\d+):([^']*)'', CHAR\(10\)", digest[0])
    if [t for _, t in lines] != tools or any(int(n) != len(t.encode()) for n, t in lines):
        fail(f"{rel}: the digest's tool lines {lines} are not the sorted declaration {tools}")
    if f"''allowed_tools={len(tools)}''" not in digest[0] or "''process=1''" not in digest[0]:
        fail(f"{rel}: the digest UPDATE of tx_nrllm_skill {uid} lacks the tool count or process=1")
    if f"allowed_tools = ''{tools_json}'' COLLATE utf8mb4_bin" not in digest[0]:
        fail(f"{rel}: the digest UPDATE of tx_nrllm_skill {uid} is not guarded by the declared list")


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
        if target and not ident:
            # Without the identifier the re-assert no longer migrates a row seeded
            # with the bare path, and the next sync duplicates it again.
            fail(f"tx_nrllm_skill {target.group(1)} (UPDATE): re-assert does not set identifier")
        elif ident and target:
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
