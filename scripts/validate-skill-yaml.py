#!/usr/bin/env python3
"""Validate YAML frontmatter in all .pi/skills/*/SKILL.md files."""
import glob
import sys
import os

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML required — pip install pyyaml")
    sys.exit(2)

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
        data = yaml.safe_load(frontmatter)
    except yaml.YAMLError as e:
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
