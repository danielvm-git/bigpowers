#!/usr/bin/env python3
# check-skill-links.py — fail on machine-absolute paths or dangling relative
# links in skill docs. Scans skills/**/SKILL.md and .pi/skills/**/SKILL.md.
# Run: python3 scripts/check-skill-links.py  (exit 1 with a report on failure)
import glob
import os
import re
import sys

MACHINE_PATH_RE = re.compile(r"file:///|/Users/|/home/|[A-Z]:\\\\Users")
LINK_RE = re.compile(r"\[([^\]]*)\]\(([^)\s]+)\)")
EXTERNAL_RE = re.compile(r"(?i)^(https?|ftp|mailto):")


def resolve_repo_root():
    here = os.path.dirname(os.path.abspath(__file__))
    if os.path.isdir(os.path.join(os.path.dirname(here), "skills")):
        return os.path.dirname(here)
    return os.getcwd()


def check(root):
    problems = []
    for tree in ("skills", os.path.join(".pi", "skills")):
        pattern = os.path.join(root, tree, "*", "SKILL.md")
        for smd in sorted(glob.glob(pattern)):
            rel = os.path.relpath(smd, root)
            with open(smd, encoding="utf-8") as f:
                text = f.read()
            for i, line in enumerate(text.splitlines(), 1):
                if MACHINE_PATH_RE.search(line):
                    problems.append(f"{rel}:{i}: machine-absolute path: {line.strip()[:100]}")
            for m in LINK_RE.finditer(text):
                target = m.group(2).split("#", 1)[0]  # strip fragment
                if not target or EXTERNAL_RE.match(target) or target.startswith(("#", "/")):
                    continue
                resolved = os.path.normpath(os.path.join(os.path.dirname(smd), target))
                if not os.path.exists(resolved):
                    problems.append(f"{rel}: dangling link -> {target}")
    return problems


def main():
    root = resolve_repo_root()
    problems = check(root)
    if problems:
        print(f"check-skill-links: {len(problems)} problem(s):")
        for p in problems:
            print(f"  {p}")
        return 1
    print("check-skill-links: OK — no machine paths or dangling links")
    return 0


if __name__ == "__main__":
    sys.exit(main())
