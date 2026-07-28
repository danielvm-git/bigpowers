#!/usr/bin/env python3
# check-skill-links.py — fail on machine-absolute paths or dangling relative
# links in skill docs. Scans skills/**/SKILL.md and .pi/skills/**/SKILL.md.
# Run: python3 scripts/check-skill-links.py  (exit 1 with a report on failure)
#
# NOTE: .cursor/rules/ and .gemini/extensions/ are intentionally excluded.
# Those trees are auto-generated from SKILL.md sources via sync-skills.sh and
# are not published to npm, so dangling links there are a rendering gap, not a
# source defect. Enable once the sync pipeline gains link-rewriting support.
# Placeholder — replace with the project's own issue tracker URL.
# See: https://github.com/OWNER/REPO/issues/78
import glob
import os
import sys

# Import shared patterns — single source of truth so the rewriter (srp-engine)
# and the gate always agree on what constitutes a "link".
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.link_utils import LINK_RE, EXTERNAL_RE, MACHINE_PATH_RE, strip_code_spans  # noqa: E402


def resolve_repo_root() -> str:
    here = os.path.dirname(os.path.abspath(__file__))
    candidate = os.path.dirname(here)  # scripts/ -> repo root
    if os.path.isdir(os.path.join(candidate, "skills")):
        return candidate
    return os.getcwd()


def check_file_links(smd: str, root: str) -> list[str]:
    """Return a list of problem strings for a single SKILL.md file."""
    rel = os.path.relpath(smd, root)
    with open(smd, encoding="utf-8") as f:
        text = f.read()

    problems = []

    # Machine-absolute path check runs on raw text (line-by-line for location).
    for i, line in enumerate(text.splitlines(), 1):
        if MACHINE_PATH_RE.search(line):
            problems.append(f"{rel}:{i}: machine-absolute path: {line.strip()[:100]}")

    # Link check runs on shadow (code spans blanked) to avoid false positives
    # on example paths shown inside fenced blocks or inline code.
    shadow = strip_code_spans(text)
    for m in LINK_RE.finditer(shadow):
        target = m.group(2).split("#", 1)[0]  # strip fragment
        if not target or EXTERNAL_RE.match(target) or target.startswith(("#", "/")):
            continue
        resolved = os.path.normpath(os.path.join(os.path.dirname(smd), target))
        if not os.path.exists(resolved):
            problems.append(f"{rel}: dangling link -> {target}")

    return problems


def check_machine_paths(path: str, root: str) -> list[str]:
    """Machine-absolute path scan for non-Markdown sources (scripts, hooks)."""
    rel = os.path.relpath(path, root)
    problems = []
    try:
        with open(path, encoding="utf-8") as f:
            text = f.read()
    except (UnicodeDecodeError, OSError):
        return problems
    for i, line in enumerate(text.splitlines(), 1):
        stripped = line.strip()
        # The pattern definition in lib/link_utils.py names these prefixes; a
        # regex describing them is not itself a violation.
        if "MACHINE_PATH_RE" in line or stripped.startswith("#"):
            continue
        if MACHINE_PATH_RE.search(line):
            problems.append(
                f"{rel}:{i}: machine-absolute path: {stripped[:100]}"
            )
    return problems


def check(root: str) -> list[str]:
    problems = []
    for tree in ("skills", os.path.join(".pi", "skills")):
        pattern = os.path.join(root, tree, "*", "SKILL.md")
        for smd in sorted(glob.glob(pattern)):
            problems.extend(check_file_links(smd, root))

    # scripts/ was previously unscanned, which let a hardcoded
    # /Users/<name>/Developer/... path ship in scripts/hermes-verify-e39s02.sh
    # while this gate reported OK.
    for pattern in (
        "scripts/*.sh",
        "scripts/lib/*.sh",
        "scripts/adapters/*.sh",
        "*.sh",
        "*.py",
    ):
        for src in sorted(glob.glob(os.path.join(root, pattern))):
            problems.extend(check_machine_paths(src, root))
    return problems


def main() -> int:
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
