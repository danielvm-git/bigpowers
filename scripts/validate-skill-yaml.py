#!/usr/bin/env python3
"""Validate YAML frontmatter in SKILL.md files (sources + generated .pi/skills).

Rules per file (sources and generated copies alike):

  R1  file must start with the frontmatter delimiter '---' at byte 0.
      pi (dist/utils/frontmatter.js) and the Agent Skills spec require the
      opening delimiter to be the first characters of the file, or pi drops
      the skill as "description is required".
      (story: BUG-2026-08-06-pi-drops-skills-frontmatter)
  R2  frontmatter must parse as YAML (PyYAML or bundled simple_yaml).
  R3  description must not embed 'model: sonnet' as literal text.
  R4  no HTML comment may appear inside the frontmatter block. `<!-- ... -->`
      is not a YAML comment: the parser reads it as a mapping key, so two of
      them repeat the key and the whole block fails to parse. Inside the
      frontmatter only `#` comments are legal.
      (story: BUG-2026-11-06-pi-frontmatter-html-comments / #173)
  R5  no duplicate top-level key in the frontmatter block. PyYAML accepts
      duplicates last-wins while pi's `yaml` package throws, so R2 alone
      cannot see this class of defect. (issue #207)

R4/R5 are dependency-free structural checks: they must fire even when only the
bundled simple_yaml fallback is available, and they must describe the exact
failure pi reports.

Exits 1 on any failure. Called by the sync-skills.sh post-generation guard
and by scripts/test-setup-no-pyyaml.sh.
"""
import glob
import re
import sys
import os

# Prefer PyYAML; fall back to the dependency-free scripts/lib/simple_yaml.py
# (story e38s01) so `bigpowers setup` works on a python3 without PyYAML.
# story: BUG-2026-07-18-setup-pyyaml-missing
_LIB = os.path.join(os.path.dirname(os.path.abspath(__file__)), "lib")
try:
    import yaml
    _load_yaml = yaml.safe_load
except ModuleNotFoundError:
    if _LIB not in sys.path:
        sys.path.insert(0, _LIB)
    from simple_yaml import parse_simple_yaml
    _load_yaml = parse_simple_yaml

# Source of truth (skills/*/SKILL.md) and the pi-distributed copy (.pi/skills).
SKILL_ROOTS = ["skills", ".pi/skills"]

# Top-level frontmatter key: column 0, `key:`, not a `#` comment or `-` item.
_TOP_LEVEL_KEY = re.compile(r"^([A-Za-z0-9_][A-Za-z0-9_.-]*):")


def structure_failures(frontmatter):
    """R4/R5 — defects that break the host parsers but not PyYAML.

    Returns a list of human-readable problems, empty when clean.
    """
    problems = []
    seen = {}
    for lineno, line in enumerate(frontmatter.split("\n"), start=2):
        stripped = line.strip()
        if stripped.startswith("<!--"):
            problems.append(
                f"R4 HTML comment inside frontmatter at line {lineno} "
                f"(use '# story: eNNsNN'); pi reads it as a mapping key"
            )
            continue
        match = _TOP_LEVEL_KEY.match(line)
        if not match:
            continue
        key = match.group(1)
        if key in seen:
            problems.append(
                f"R5 duplicate frontmatter key '{key}' at line {lineno} "
                f"(first seen at line {seen[key]}); pi throws 'Map keys must be unique'"
            )
            continue
        seen[key] = lineno
    return problems


def validate_tree(root):
    """Return (passed, delimiter, parse, semantic, structure) failure lists."""
    files = sorted(glob.glob(os.path.join(root, "*/SKILL.md")))
    parse_failures = []
    semantic_failures = []
    delimiter_failures = []
    structure_problems = []
    passed = []

    for path in files:
        skill_name = os.path.basename(os.path.dirname(path))
        with open(path) as f:
            content = f.read()

        # R1 — pi's frontmatter gate: opening delimiter must be at byte 0.
        if not content.startswith("---"):
            delimiter_failures.append((skill_name, "file must start with '---' (story tags belong inside the frontmatter block or below it)"))
            continue

        parts = content.split("---", 2)
        if len(parts) < 3:
            parse_failures.append((skill_name, "missing frontmatter delimiters"))
            continue

        frontmatter = parts[1]

        structural = structure_failures(frontmatter)
        if structural:
            structure_problems.append((skill_name, structural))
            continue

        try:
            data = _load_yaml(frontmatter)
        except Exception as e:
            parse_failures.append((skill_name, str(e).split("\n")[0]))
            continue

        if data is None:
            parse_failures.append((skill_name, "empty frontmatter"))
            continue

        # R3 — semantic check: model hint embedded in description
        desc = data.get("description", "")
        if desc and "model: sonnet" in desc:
            semantic_failures.append(skill_name)

        passed.append(skill_name)

    return passed, delimiter_failures, parse_failures, semantic_failures, structure_problems


all_passed = []
all_delimiter = []
all_parse = []
all_semantic = []
all_structure = []

for root in SKILL_ROOTS:
    passed, delimiter_failures, parse_failures, semantic_failures, structure_problems = validate_tree(root)
    all_passed += passed
    all_delimiter += delimiter_failures
    all_parse += parse_failures
    all_semantic += semantic_failures
    all_structure += structure_problems
    total = len(passed) + len(delimiter_failures) + len(parse_failures) + len(semantic_failures) + len(structure_problems)
    print(f"[{root}] SKILL.md files: {total} — parse OK: {len(passed)}")

print()
print(f"Total SKILL.md files: {len(all_passed) + len(all_delimiter) + len(all_parse) + len(all_semantic) + len(all_structure)}")
print(f"Parse OK: {len(all_passed)}")
print(f"Delimiter FAIL (must start with '---'): {len(all_delimiter)}")
print(f"Parse FAIL: {len(all_parse)}")
print(f"Semantic issues (model in desc): {len(all_semantic)}")
print(f"Structure FAIL (R4 HTML comment / R5 duplicate key): {len(all_structure)}")
print()

if all_delimiter:
    print("=== DELIMITER FAILURES (file does not start with '---') ===")
    for name, err in all_delimiter:
        print(f"  {name}: {err}")
    print()

if all_parse:
    print("=== PARSE FAILURES ===")
    for name, err in all_parse:
        print(f"  {name}: {err}")
    print()

if all_semantic:
    print("=== SEMANTIC ISSUES (model embedded in description) ===")
    for name in sorted(all_semantic):
        print(f"  {name}")
    print()

if all_structure:
    print("=== STRUCTURE FAILURES (pi would drop the skill) ===")
    for name, problems in all_structure:
        for problem in problems:
            print(f"  {name}: {problem}")
    print()

if all_delimiter or all_parse or all_semantic or all_structure:
    n = len(all_delimiter) + len(all_parse) + len(all_semantic) + len(all_structure)
    print(
        f"FAIL: {n} issues ({len(all_delimiter)} delimiter + {len(all_parse)} parse + "
        f"{len(all_semantic)} semantic + {len(all_structure)} structure)"
    )
    sys.exit(1)
else:
    print("PASS: all SKILL.md YAML frontmatter valid (sources + .pi/skills)")
    sys.exit(0)
