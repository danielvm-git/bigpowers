#!/usr/bin/env bash
# story: e45s02
# generate-reference-nav.sh — rebuild the "| Lines | Section |" nav table at the
# top of each skills/*/REFERENCE.md from the file's actual headings.
#
# These tables are a token-economy aid: they let an agent jump to a line range
# instead of reading the whole file. Hand-maintained, they drift the moment any
# section grows — at the time this was written, 4 of 10 cited a line number past
# end-of-file, so the index pointed past the document it indexed.
#
# Usage: bash scripts/generate-reference-nav.sh [--check]
#   --check  fail if any committed nav table is stale (for CI)

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

MODE="${1:-write}"

$PYTHON - "$MODE" <<'PY'
import sys, glob, re

mode = sys.argv[1]
stale, rewritten = [], []

def rebuild(lines):
    """One pass: replace the nav table with ranges derived from the headings."""
    hdr = next((i for i, l in enumerate(lines) if l.strip() == "| Lines | Section |"), None)
    if hdr is None:
        return None
    end = hdr + 2
    while end < len(lines) and lines[end].startswith("|"):
        end += 1

    # Section boundaries come from ## / ### headings; the title is line 1.
    heads = [(i + 1, l) for i, l in enumerate(lines) if re.match(r"^#{2,3} ", l)]
    # "## Navigation" is itself a heading — do not synthesize a second row for it.
    rows = ["| Lines | Section |", "|-------|---------|", "| 1 | Title |"]
    # split("\n") on a trailing newline yields one extra empty element; the real
    # last line is the last non-empty index.
    last = len(lines)
    while last > 0 and lines[last - 1] == "":
        last -= 1
    for idx, (ln, text) in enumerate(heads):
        nxt = heads[idx + 1][0] - 1 if idx + 1 < len(heads) else last
        name = re.sub(r"^#{2,3} ", "", text).strip()
        rows.append("| %d–%d | %s |" % (ln, nxt, name))
    return lines[:hdr] + rows + lines[end:]


for path in sorted(glob.glob("skills/*/REFERENCE.md")):
    original = open(path, encoding="utf-8").read().split("\n")

    # Rewriting the table changes the line numbers the table reports, so iterate
    # to a fixed point rather than assuming one pass converges.
    lines = original
    for _ in range(10):
        nxt = rebuild(lines)
        if nxt is None or nxt == lines:
            break
        lines = nxt
    if lines is None:
        continue

    new = lines
    if new == original:
        continue
    lines = original  # keep the staleness comparison against what is committed
    if mode == "--check":
        stale.append(path)
    else:
        open(path, "w", encoding="utf-8").write("\n".join(new))
        rewritten.append(path)

if mode == "--check":
    if stale:
        print("generate-reference-nav: stale nav table(s):", file=sys.stderr)
        for s in stale:
            print("  %s" % s, file=sys.stderr)
        print("run: bash scripts/generate-reference-nav.sh", file=sys.stderr)
        sys.exit(1)
    print("generate-reference-nav: all nav tables current")
else:
    for r in rewritten:
        print("  rebuilt %s" % r)
    print("generate-reference-nav: %d table(s) rebuilt" % len(rewritten))
PY
