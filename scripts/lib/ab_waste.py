#!/usr/bin/env python3
# story: e58s09 e58s10
"""Lean waste metrics for one A/B run, from its final patch and its pi transcript.

Patch (any adapter): changed lines per file class, the reference solution's size, extra files,
leftover scratch files and the review load a person would face. Transcript (pi): relearning
(rereads, repeated commands), defects and rework (failing test runs after the first build edit,
re-edits), first-time-through and process cycle efficiency. See LEAN-VSM_LATEST.md and
specs/benchmarks/ab/vsm.yaml (file classes reuse the stage rules; `leftovers` regex).
"""
from __future__ import annotations

import functools
import gzip
import json
import re
import shutil
import subprocess
import tempfile
from collections import Counter
from pathlib import Path

from ab_vsm import classify_call, load_rules, vsm_from_pi  # type: ignore[import]

CLASS_OF_STAGE = {"build": "product", "test": "test", "maintain": "doc", "plan": "plan"}
FAILED = re.compile(r'"exit_code":\s*[1-9]|(?:^|\\n|\n)\s*(?:ℹ|#)\s*fail\s+[1-9]|(?:^|\\n|\n)not ok ')


def git(cwd: Path, *args: str) -> str:
    res = subprocess.run(["git", "-c", "user.name=ab", "-c", "user.email=ab@local", *args],
                         cwd=cwd, capture_output=True, text=True)
    return res.stdout


def file_class(path: str, rules: dict) -> str:
    cls = CLASS_OF_STAGE.get(classify_call("edit", {"path": path}, rules), "product")
    return "doc" if cls == "product" and path.endswith(".md") else cls


def numstat(cwd: Path, base: str) -> dict[str, int]:
    changed = {}
    for line in git(cwd, "diff", "--cached", "--numstat", base).splitlines():
        added, deleted, path = line.split("\t", 2)
        changed[path] = sum(int(n) for n in (added, deleted) if n.isdigit())
    return changed


@functools.lru_cache(maxsize=None)
def solution_files(task_dir: str) -> dict[str, int] | None:
    """Changed lines per file of the reference solution, applied over the fixture."""
    task = Path(task_dir)
    if not (task / "solution").is_dir():
        return None
    work = Path(tempfile.mkdtemp(prefix="ab-solution-"))
    try:
        shutil.copytree(task / "fixture", work, dirs_exist_ok=True)
        git(work, "init", "-q")
        git(work, "add", "-A")
        git(work, "commit", "-q", "--no-verify", "-m", "fixture")
        shutil.copytree(task / "solution", work, dirs_exist_ok=True)
        git(work, "add", "-A")
        return numstat(work, "HEAD")
    finally:
        shutil.rmtree(work, ignore_errors=True)


def patch_waste(workdir: Path, base: str, task_dir: Path, patch_path: Path | None, rules: dict) -> dict:
    git(workdir, "add", "-A")
    patch = git(workdir, "diff", "--cached", base)
    if patch_path is not None:
        patch_path.parent.mkdir(parents=True, exist_ok=True)
        patch_path.write_bytes(gzip.compress(patch.encode()))
    changed = numstat(workdir, base)
    lines = Counter()
    for path, n in changed.items():
        lines[file_class(path, rules)] += n
    added = [line[2:] for line in git(workdir, "diff", "--cached", "--name-status", base).splitlines()
             if line.startswith("A\t")]
    solution = solution_files(str(task_dir))
    solution_lines = sum(solution.values()) if solution else None
    product = [p for p in changed if file_class(p, rules) == "product"]
    doc_words = sum(len(line[1:].split()) for line in md_added_lines(patch))
    return {
        "product_lines": lines["product"], "test_lines": lines["test"],
        "doc_lines": lines["doc"], "plan_lines": lines["plan"],
        "solution_lines": solution_lines,
        "diff_ratio": round(lines["product"] / solution_lines, 3) if solution_lines else None,
        "extra_files": sorted(p for p in product if solution is not None and p not in solution),
        "leftovers": sorted(p for p in added if re.search(rules["leftovers"], p)),
        "review_load": sum(changed.values()) + len(changed) + doc_words,
    }


def md_added_lines(patch: str) -> list[str]:
    out, in_md = [], False
    for line in patch.splitlines():
        if line.startswith("+++ "):
            in_md = line.endswith(".md")
        elif in_md and line.startswith("+"):
            out.append(line)
    return out


def tool_calls(stdout: str) -> list[dict]:
    """Ordered tool calls with their stage and whether a test run failed."""
    calls, by_id = [], {}
    for line in stdout.splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(event, dict):
            continue
        if event.get("type") == "tool_execution_start":
            call = {"tool": event.get("toolName", ""), "args": event.get("args") or {}, "failed": False}
            by_id[event.get("toolCallId")] = call
            calls.append(call)
        elif event.get("type") == "tool_execution_end" and event.get("toolCallId") in by_id:
            by_id[event["toolCallId"]]["failed"] = bool(FAILED.search(json.dumps(event.get("result"), ensure_ascii=False)))
    return calls


def transcript_waste(stdout: str, rules: dict | None = None) -> dict | None:
    rules = rules or load_rules()
    vsm = vsm_from_pi(stdout, rules)
    calls = tool_calls(stdout)
    if vsm is None and not calls:
        return None
    for call in calls:
        call["stage"] = classify_call(call["tool"], call["args"], rules)
    reads = Counter(c["args"].get("path") for c in calls if c["tool"] == "read")
    commands = Counter(c["args"].get("command") for c in calls if c["tool"] == "bash" and c["stage"] != "test")
    edits = Counter(c["args"].get("path") for c in calls if c["tool"] in ("edit", "write"))
    first_build = next((i for i, c in enumerate(calls) if c["stage"] == "build"), None)
    runs = [c for c in calls if c["tool"] == "bash" and c["stage"] == "test"]
    after = [c for c in calls[first_build:] if c in runs] if first_build is not None else []
    rework = sum(c["failed"] for c in after)
    redundant = redundant_runs(calls)
    stages = (vsm or {}).get("stages", {})
    lead = (vsm or {}).get("lead_time_s") or 0
    value_add = sum(stages.get(s, {}).get("s", 0) for s in ("build", "test"))
    return {
        "rereads": sum(n - 1 for n in reads.values()),
        "repeated_commands": sum(n - 1 for n in commands.values()),
        "test_runs": len(runs), "redundant_test_runs": redundant, "rework_loops": rework,
        "reedits": sum(n - 1 for n in edits.values()),
        "ftt": bool(after) and rework == 0,
        "pce": round(value_add / lead, 3) if lead else None,
    }


def redundant_runs(calls: list[dict]) -> int:
    """Passing test runs with no file edited since the previous passing run (overprocessing, e58s10)."""
    redundant, green, dirty = 0, False, False
    for call in calls:
        if call["tool"] in ("edit", "write"):
            dirty = True
        elif call["tool"] == "bash" and call["stage"] == "test" and not call["failed"]:
            redundant += green and not dirty
            green, dirty = True, False
    return redundant


EMPTY_TRANSCRIPT = dict.fromkeys(["rereads", "repeated_commands", "test_runs", "redundant_test_runs",
                                  "rework_loops", "reedits", "ftt", "pce"])


def waste_for(workdir: Path, base: str, stdout: str, parser: str, task_dir: Path,
              patch_path: Path | None = None) -> dict:
    """The run record's waste block; transcript metrics are None for non-pi adapters."""
    rules = load_rules()
    transcript = transcript_waste(stdout, rules) if parser == "pi-json" else None
    return {**patch_waste(workdir, base, task_dir, patch_path, rules), **(transcript or EMPTY_TRANSCRIPT)}
