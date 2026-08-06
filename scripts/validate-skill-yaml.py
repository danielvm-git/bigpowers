#!/usr/bin/env python3
"""Validate YAML frontmatter in SKILL.md files (sources + generated .pi/skills).

Rules per file (sources and generated copies alike):

  R1  file must start with the frontmatter delimiter '---' at byte 0.
      pi (dist/utils/frontmatter.js) and the Agent Skills spec require the
      opening delimiter to be the first characters of the file. Story tags
      (`# story:` / `<!-- story: -->`) must live INSIDE the frontmatter block
      as YAML comments, or below the closing delimiter — never above it,
      or pi drops the skill as "description is required".
      (story: BUG-2026-08-06-pi-drops-skills-frontmatter)
  R2  frontmatter must parse as YAML (PyYAML or bundled simple_yaml).
  R3  description must not embed 'model: sonnet' as literal text.

Exits 1 on any failure. Called by the sync-skills.sh post-generation guard
and by scripts/test-setup-no-pyyaml.sh.
"""
import glob
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


def validate_tree(root):
    """Return (passed, delimiter_failures, parse_failures, semantic_failures)."""
    files = sorted(glob.glob(os.path.join(root, "*/SKILL.md")))
    parse_failures = []
    semantic_failures = []
    delimiter_failures = []
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

    return passed, delimiter_failures, parse_failures, semantic_failures


all_passed = []
all_delimiter = []
all_parse = []
all_semantic = []

for root in SKILL_ROOTS:
    passed, delimiter_failures, parse_failures, semantic_failures = validate_tree(root)
    all_passed += passed
    all_delimiter += delimiter_failures
    all_parse += parse_failures
    all_semantic += semantic_failures
    total = len(passed) + len(delimiter_failures) + len(parse_failures) + len(semantic_failures)
    print(f"[{root}] SKILL.md files: {total} — parse OK: {len(passed)}")

print()
print(f"Total SKILL.md files: {len(all_passed) + len(all_delimiter) + len(all_parse) + len(all_semantic)}")
print(f"Parse OK: {len(all_passed)}")
print(f"Delimiter FAIL (must start with '---'): {len(all_delimiter)}")
print(f"Parse FAIL: {len(all_parse)}")
print(f"Semantic issues (model in desc): {len(all_semantic)}")
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

if all_delimiter or all_parse or all_semantic:
    n = len(all_delimiter) + len(all_parse) + len(all_semantic)
    print(f"FAIL: {n} issues ({len(all_delimiter)} delimiter + {len(all_parse)} parse + {len(all_semantic)} semantic)")
    sys.exit(1)
else:
    print("PASS: all SKILL.md YAML frontmatter valid (sources + .pi/skills)")
    sys.exit(0)
