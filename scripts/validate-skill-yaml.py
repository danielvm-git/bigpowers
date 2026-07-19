#!/usr/bin/env python3
"""Validate YAML frontmatter in all .pi/skills/*/SKILL.md files."""
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

SKILLS_DIR = ".pi/skills"
files = sorted(glob.glob(f"{SKILLS_DIR}/*/SKILL.md"))

parse_failures = []
semantic_failures = []
passed = []

for path in files:
    skill_name = os.path.basename(os.path.dirname(path))
    with open(path) as f:
        content = f.read()

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

    # Semantic check: model hint embedded in description
    desc = data.get("description", "")
    if desc and "model: sonnet" in desc:
        semantic_failures.append(skill_name)

    passed.append(skill_name)

# Report
print(f"Total SKILL.md files: {len(files)}")
print(f"Parse OK: {len(passed)}")
print(f"Parse FAIL: {len(parse_failures)}")
print(f"Semantic issues (model in desc): {len(semantic_failures)}")
print()

if parse_failures:
    print("=== PARSE FAILURES ===")
    for name, err in parse_failures:
        print(f"  {name}: {err}")
    print()

if semantic_failures:
    print("=== SEMANTIC ISSUES (model embedded in description) ===")
    for name in sorted(semantic_failures):
        print(f"  {name}")
    print()

if parse_failures or semantic_failures:
    print(f"FAIL: {len(parse_failures)} parse + {len(semantic_failures)} semantic issues")
    sys.exit(1)
else:
    print("PASS: all SKILL.md YAML frontmatter valid")
    sys.exit(0)
