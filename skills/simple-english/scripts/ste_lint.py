#!/usr/bin/env python3
"""Machine gate for ASD-STE100 Simplified Technical English.

A deterministic regex pass over technical prose. It counts the violations a
machine can catch: sentence length, contractions, banned modals, perfect
tenses, "-ing" clauses, semicolons, Latin abbreviations, slop words, trailing
conditions, synonym rotation, and terminology drift. It adds two structural
checks the upstream STE skills omit: heading hierarchy and non-descriptive link
text. When Vale is on PATH and a `.vale.ini` lives up the tree, it defers the
style layer to Vale and keeps only the STE checks.

Ceiling: this is a regex pass, not a grammar parser. It undercounts (no
passive-voice detection, no part-of-speech checks) and it can misread sentence
bounds in unusual markdown. Counts are comparable between two texts run through
the same version. They are not a compliance verdict. No tool can guarantee STE
compliance.

Synthesis of two MIT sources:
  - ste_lint.py            AminBlg/SimpleEnglish        (11 STE checks, JSON mode)
  - check_docs.py          JuanMarchetto/doc-standards  (drift detector, Vale handoff)

Usage:
  python3 ste_lint.py --self-test
  python3 ste_lint.py file.md                       # lint one file (exit 1 on error)
  python3 ste_lint.py path/                         # lint a tree of markdown
  python3 ste_lint.py file.md --json                # JSON report instead of line output
  python3 ste_lint.py file.md --type procedural     # procedural limit (20); default descriptive (25)
  cat text.md | python3 ste_lint.py -               # read from stdin
  python3 ste_lint.py file.md --no-vale             # force built-in style checks

Exit code 1 on any error-level finding, else 0. Warnings never fail the gate.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import List, Tuple

# --------------------------------------------------------------------------
# Rule constants (paraphrased from ASD-STE100 Issue 9, 2025-01-15)
# --------------------------------------------------------------------------

LIMITS = {"procedural": 20, "descriptive": 25}
DEFAULT_TYPE = "descriptive"
LONG_SENTENCE_ERROR = 40  # hard error regardless of mode (prose, not a step)

# Approved modals: can, will, must. Banned: should, would, may, might, could.
BANNED_MODALS = re.compile(r"\b(should|would|may|might|could)\b", re.I)
PERFECT = re.compile(
    r"\b(has|have|had)\s+been\b|\b(has|have)\s+\w+ed\b", re.I
)
PROGRESSIVE_PASSIVE = re.compile(
    r"\b(?:is|are|was|were)\s+being\s+\w+(?:ed|en)?\b", re.I
)
CONTRACTION = re.compile(
    r"\b\w+(n't|'ll|'re|'ve|'d)\b|\bit's\b|\byou're\b|\bdon't\b", re.I
)
# "-ing" clause used as a verb (Rule 3.5): ", making ...", ", allowing ..."
ING_CLAUSE = re.compile(
    r",\s*(mak|allow|enabl|ensur|highlight|creat|provid|offer|help|reduc|"
    r"improv|lead|caus|result)ing\b",
    re.I,
)
LATIN = re.compile(r"\b(e\.g\.|i\.e\.|etc\.?)(?=[\s,);]|$)", re.I)
SLOP = re.compile(
    r"\b(simply|seamlessly|effortlessly|robust|leverag\w*|utiliz\w*|"
    r"comprehensive|powerful|blazingly|streamlin\w*|facilitat\w*|"
    r"performant|plethora|myriad|delve|crucial|pivotal)\b",
    re.I,
)
# Condition at the wrong end of a sentence (Rule 5.4): "... if X."
TRAILING_COND = re.compile(r"\w[^.!?\n]{3,}\s\b(if|when)\b\s", re.I)

# Positional references break under retrieval: "as mentioned above".
POSITIONAL = re.compile(
    r"\b(?:as\s+(?:mentioned|shown|described|noted)\s+)?(?:above|below)\b"
    r"(?=[,.\s)])",
    re.I,
)

# Terminology drift: 2+ synonyms each used 2+ times = drift.
SYNONYM_SETS: List[List[str]] = [
    ["verify", "check", "confirm", "ensure", "make sure", "validate"],
    ["cancel", "abort", "terminate"],
    ["remove", "delete", "erase"],
    ["display", "show", "render"],
    ["directory", "folder"],
    ["parameter", "argument", "flag", "option"],
]

# Markdown atoms.
MD_LINK = re.compile(r"\[([^\]]+)\]\(([^)#\s]+)(?:#[^)\s]*)?\)")
HEADING = re.compile(r"^(#{1,6})\s+(.*)$")
CODE_FENCE = re.compile(r"^(```|~~~)")
STEP_ITEM = re.compile(r"^\s*(?:\d+[.)]|[-*+])\s+")


# --------------------------------------------------------------------------
# Text cleaning
# --------------------------------------------------------------------------


def strip_inline(text: str) -> str:
    """Remove markdown atoms that would distort word counts and word scans.

    Order matters: strip images and links before bare URLs, or the closing
    paren of a link gets eaten by the URL pass.
    """
    text = re.sub(r"!\[[^\]]*\]\([^)]*\)", "", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"`[^`\n]+`", "CODESPAN", text)
    text = re.sub(r"https?://[^\s)]+", "URL", text)
    return text


def strip_code(text: str) -> str:
    """Strip fenced code blocks, headings, and tables before STE scans."""
    text = re.sub(r"```.*?```", " ", text, flags=re.S)
    text = re.sub(r"~~~.*?~~~", " ", text, flags=re.S)
    text = strip_inline(text)
    text = re.sub(r"^#+\s.*$", " ", text, flags=re.M)  # headings exempt (8.6)
    text = re.sub(r"^[|].*$", " ", text, flags=re.M)  # table rows exempt
    text = re.sub(r"^\s*([-*]|\d+\.)\s+", "", text, flags=re.M)  # list markers
    return text


def sentences(text: str) -> List[str]:
    """Split into sentences on terminal punctuation followed by a capital."""
    parts = re.split(r"(?<=[.!?:])\s+(?=[A-Z`\"'])", text)
    return [p.strip() for p in parts if len(p.strip().split()) >= 2]


# --------------------------------------------------------------------------
# STE checks (file-level counts)
# --------------------------------------------------------------------------


def ste_counts(body: str, text_type: str) -> dict:
    """Return per-violation counts for the STE checks on a cleaned body."""
    limit = LIMITS[text_type]
    sents = sentences(body)
    lengths = [len(s.split()) for s in sents]
    counts: dict = {}
    counts["sentence_over_limit"] = sum(1 for n in lengths if n > limit)
    counts["contraction"] = len(CONTRACTION.findall(body))
    counts["banned_modal"] = len(BANNED_MODALS.findall(body))
    counts["perfect_tense"] = len(PERFECT.findall(body))
    counts["progressive_passive"] = len(PROGRESSIVE_PASSIVE.findall(body))
    counts["ing_clause"] = len(ING_CLAUSE.findall(body))
    counts["semicolon"] = body.count(";")
    counts["latin_abbrev"] = len(LATIN.findall(body))
    counts["slop_word"] = len(SLOP.findall(body))
    counts["trailing_condition"] = sum(
        1
        for s in sents
        if TRAILING_COND.search(s) and not re.match(r"^(if|when)\b", s, re.I)
    )
    counts["positional_reference"] = len(POSITIONAL.findall(body))

    rotation = 0
    for syn_set in SYNONYM_SETS:
        used = [
            w
            for w in syn_set
            if len(re.findall(rf"\b{re.escape(w)}\b", body, re.I)) >= 2
        ]
        if len(used) >= 2:
            rotation += len(used) - 1
    counts["synonym_rotation"] = rotation

    words = max(1, len(body.split()))
    total = sum(counts.values())
    return {
        "type": text_type,
        "words": words,
        "sentences": len(sents),
        "mean_sentence_words": round(sum(lengths) / max(1, len(lengths)), 1),
        "longest_sentence_words": max(lengths, default=0),
        "violations": counts,
        "violations_total": total,
        "violations_per_100w": round(100.0 * total / words, 2),
    }


# --------------------------------------------------------------------------
# Structural checks (line-level, file-aware) — from check_docs.py
# --------------------------------------------------------------------------

# Severity: "error" fails the gate; "warning" does not.
POSITIONAL_FINDING = ("warning", "positional reference breaks under retrieval; link to the section")


def lint_structural(path: Path, lines: List[str]) -> List[Tuple[int, str, str]]:
    """Heading-hierarchy + link-text checks. Returns (line_no, level, msg)."""
    findings: List[Tuple[int, str, str]] = []
    in_code = False
    levels_seen: List[int] = []
    headings_text: List[str] = []
    h1_count = 0
    for i, raw in enumerate(lines, 1):
        if CODE_FENCE.match(raw.strip()):
            in_code = not in_code
            continue
        if in_code:
            continue
        m = HEADING.match(raw)
        if m:
            level, text = len(m.group(1)), m.group(2).strip()
            if level == 1:
                h1_count += 1
                if h1_count > 1:
                    findings.append((i, "error", "multiple h1 headings on one page"))
            if levels_seen and level > levels_seen[-1] + 1:
                findings.append(
                    (i, "error", f"skipped heading level (h{levels_seen[-1]} -> h{level})")
                )
            levels_seen.append(level)
            low = text.lower()
            if low in headings_text:
                findings.append(
                    (i, "warning", f"duplicate heading '{text}' (anchors collide)")
                )
            headings_text.append(low)
            continue
        for link_m in MD_LINK.finditer(raw):
            label = link_m.group(1).strip().lower()
            target = link_m.group(2)
            if label in ("here", "this", "link", "this page"):
                findings.append((i, "error", f"non-descriptive link text '{label}'"))
            if not target.startswith(("http://", "https://", "mailto:", "/")):
                if not (path.parent / target).exists():
                    findings.append((i, "error", f"broken relative link '{target}'"))
    return findings


# --------------------------------------------------------------------------
# Linter
# --------------------------------------------------------------------------


class Linter:
    def __init__(self, text_type: str, use_vale: bool, style: bool):
        self.text_type = text_type
        self.vale = use_vale and shutil.which("vale") is not None
        # Built-in style checks run only when Vale does not take the style layer.
        self.style = style and not self.vale
        self.findings: List[Tuple[Path, int, str, str]] = []

    def add(self, path: Path, line: int, level: str, msg: str) -> None:
        self.findings.append((path, line, level, msg))

    def lint_file(self, path: Path) -> None:
        raw_text = path.read_text(encoding="utf-8", errors="replace")
        lines = raw_text.splitlines()

        # --- STE checks on the cleaned body ---
        body = strip_code(raw_text)
        rep = ste_counts(body, self.text_type)
        for key, n in rep["violations"].items():
            if n <= 0:
                continue
            level = "error" if key in ("banned_modal", "contraction") else "warning"
            self.add(path, 0, level, f"{key}: {n}")

        # hard error on runaway sentences regardless of mode
        if rep["longest_sentence_words"] > LONG_SENTENCE_ERROR:
            self.add(
                path,
                0,
                "error",
                f"sentence has {rep['longest_sentence_words']} words "
                f"(hard limit {LONG_SENTENCE_ERROR})",
            )

        # --- Structural checks (heading hierarchy, link text) ---
        for line_no, level, msg in lint_structural(path, lines):
            self.add(path, line_no, level, msg)

        # --- Built-in style layer (only when Vale is absent) ---
        if self.style:
            for sent in sentences(strip_inline(raw_text)):
                if POSITIONAL.search(sent):
                    self.add(path, 0, POSITIONAL_FINDING[0], POSITIONAL_FINDING[1])

    def run_vale(self, target: Path) -> None:
        ini = None
        for parent in [target, *list(target.parents)]:
            if (parent / ".vale.ini").exists():
                ini = parent / ".vale.ini"
                break
        if ini is None:
            # No config: fall back to built-in style checks.
            self.style = True
            self.vale = False
            return
        r = subprocess.run(
            ["vale", "--output=line", str(target)],
            capture_output=True,
            text=True,
            cwd=str(ini.parent),
        )
        for line in r.stdout.splitlines():
            print(line)
        if r.returncode != 0:
            self.findings.append((target, 0, "error", "vale reported errors (above)"))


# --------------------------------------------------------------------------
# Self-test (used by the skill's `→ verify:` gate)
# --------------------------------------------------------------------------

SLOP_FIXTURE = """Leveraging our robust retry mechanism, failed uploads are automatically
reattempted, ensuring data integrity is maintained throughout the entire process which has
been designed from the ground up to gracefully handle even the most challenging network
interruptions. You should verify your credentials; it's also worth checking the settings,
e.g. the timeout config. Contact support if the problem persists."""

CLEAN_FIXTURE = """The system retries a failed upload automatically. This process keeps the data correct.

If failures continue, make sure that your credentials are correct. If the problem continues, contact support."""

# Genuine terminology drift: two synonyms (check, verify) each used twice.
DRIFT_FIXTURE = """To check the build, run the test suite. Then verify the output log.
Check the exit code. Verify the result against the baseline."""


def self_test() -> None:
    """Assert the linter catches what it must and clears what it should."""
    slop = ste_counts(strip_code(SLOP_FIXTURE), "procedural")
    clean = ste_counts(strip_code(CLEAN_FIXTURE), "procedural")
    drift = ste_counts(strip_code(DRIFT_FIXTURE), "procedural")
    assert slop["violations"]["sentence_over_limit"] >= 1, slop
    assert slop["violations"]["banned_modal"] >= 1, slop
    assert slop["violations"]["contraction"] >= 1, slop
    assert slop["violations"]["perfect_tense"] >= 1, slop
    assert slop["violations"]["ing_clause"] >= 1, slop
    assert slop["violations"]["semicolon"] >= 1, slop
    assert slop["violations"]["latin_abbrev"] >= 1, slop
    assert slop["violations"]["slop_word"] >= 2, slop
    assert slop["violations"]["trailing_condition"] >= 1, slop
    # The slop fixture mentions "verify" and "checking" only once each, so the
    # strict drift detector (2+ synonyms each used 2+ times) must stay silent.
    assert slop["violations"]["synonym_rotation"] == 0, slop
    assert drift["violations"]["synonym_rotation"] >= 1, drift
    assert clean["violations_total"] == 0, clean

    # Structural: duplicate headings and a skipped level must flag.
    struct = lint_structural(
        Path("x"),
        ["# Title", "## Sub", "#### Skipped", "#### Skipped", ""],
    )
    assert any("skipped heading" in m for _, _, m in struct), struct
    assert any("duplicate heading" in m for _, _, m in struct), struct

    # Non-descriptive link text must flag as an error.
    link_findings = lint_structural(Path("x"), ["See [here](./x.md) for more."])
    assert any(lvl == "error" for _, lvl, _ in link_findings), link_findings

    print(
        "self-test OK: "
        f"{slop['violations_total']} violations in slop fixture, "
        "0 in clean, structural checks pass"
    )


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------


def gather_files(target: Path) -> List[Path]:
    if target.is_file():
        return [target]
    return sorted(target.rglob("*.md"))


def main(argv: List[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="STE machine gate.")
    ap.add_argument("target", nargs="?", help="file or dir to lint, or '-' for stdin")
    ap.add_argument("--type", choices=sorted(LIMITS), default=DEFAULT_TYPE)
    ap.add_argument("--json", action="store_true", help="emit JSON report only")
    ap.add_argument("--no-vale", action="store_true", help="force built-in style checks")
    ap.add_argument("--self-test", action="store_true", help="run built-in assertions and exit")
    args = ap.parse_args(argv)

    if args.self_test:
        self_test()
        return 0

    if args.target is None or args.target == "":
        ap.error("the following arguments are required: target")

    # stdin path
    if args.target == "-":
        text = sys.stdin.read()
        rep = ste_counts(strip_code(text), args.type)
        print(json.dumps(rep, indent=2))
        return 0 if rep["violations_total"] == 0 else 1

    target = Path(args.target).resolve()
    if not target.exists():
        print(f"target not found: {target}", file=sys.stderr)
        return 2

    files = gather_files(target)
    if not files:
        print(f"no markdown files under {target}")
        return 0

    linter = Linter(args.type, use_vale=not args.no_vale, style=True)
    if linter.vale and target.is_dir():
        linter.run_vale(target)
    for f in files:
        linter.lint_file(f)

    if args.json:
        rep = {
            "files": len(files),
            "findings": [
                {"path": str(p), "line": n, "level": lvl, "msg": msg}
                for (p, n, lvl, msg) in linter.findings
            ],
        }
        print(json.dumps(rep, indent=2))
    else:
        for path, line, level, msg in linter.findings:
            loc = f"{path}:{line}" if line else f"{path}"
            print(f"{loc}: [{level}] {msg}")

    errors = sum(1 for *_, lvl, _ in linter.findings if lvl == "error")
    warnings = sum(1 for *_, lvl, _ in linter.findings if lvl == "warning")
    style_layer = "vale" if linter.vale else "built-in"
    print(
        f"\n{errors} error(s), {warnings} warning(s) in {len(files)} file(s) "
        f"[style layer: {style_layer}]"
    )
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
