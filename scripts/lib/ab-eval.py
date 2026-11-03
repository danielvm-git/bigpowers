#!/usr/bin/env python3
# story: e58s01 e58s02 e58s03 e58s05 e58s06 e58s07
"""A/B eval: run the same tasks with and without bigpowers and grade only the outcome.

Each run gets a fresh temp git workdir (outside the repo) copied from the task fixture.
The arm setup runs, the agent runs through an adapter command, then hidden tests are
copied in and the task's grade command decides pass/fail. Advisory: exit 0 after a
completed run, 2 on configuration errors.
"""
from __future__ import annotations

import argparse
import gzip
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timezone
from difflib import SequenceMatcher
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ab_metrics import parse_metrics, tap_score, tap_failures, tap_failed_names  # type: ignore[import]  # noqa: E402
from ab_report import (  # type: ignore[import]  # noqa: E402
    BOOTSTRAP_RESAMPLES, BOOTSTRAP_SEED, aggregate, bigpowers_sha, print_summary, write_reports,
)

REPO_ROOT = Path(__file__).resolve().parents[2]
AB_DIR = REPO_ROOT / "specs" / "benchmarks" / "ab"
DEFAULT_CONFIG = AB_DIR / "config.yaml"
DEFAULT_TASKS_DIR = AB_DIR / "tasks"
DEFAULT_OUT = REPO_ROOT / "specs" / "benchmarks" / "reports"
DEFAULT_ARMS = "vanilla,bigpowers"
GIT_ID = ["-c", "user.name=ab-eval", "-c", "user.email=ab-eval@localhost", "-c", "commit.gpgsign=false"]


class ConfigError(Exception):
    pass


# ── loading ──────────────────────────────────────────────────────────────────

def load_yaml(path: Path) -> dict:
    if not path.is_file():
        raise ConfigError(f"missing file: {path}")
    return yaml.safe_load(path.read_text()) or {}


def load_tasks(tasks_dir: Path, wanted: list[str] | None) -> list[dict]:
    tasks = {}
    for task_yaml in sorted(tasks_dir.glob("*/task.yaml")):
        task = load_yaml(task_yaml)
        task["dir"] = task_yaml.parent
        tasks[task["id"]] = task
    if not wanted:
        return list(tasks.values())
    unknown = [t for t in wanted if t not in tasks]
    if unknown:
        raise ConfigError(f"unknown task(s) {unknown}; valid: {sorted(tasks)}")
    return [tasks[t] for t in wanted]


def pick(section: dict, names: list[str], kind: str) -> dict:
    unknown = [n for n in names if n not in section]
    if unknown:
        raise ConfigError(f"unknown {kind}(s) {unknown}; valid: {sorted(section)}")
    return {n: section[n] for n in names}


def resolve_adapter(config: dict, name: str, custom_cmd: str | None, parser: str | None) -> dict:
    if custom_cmd:
        return {"name": "custom", "command": custom_cmd, "parser": parser or "none"}
    adapter = dict(pick(config.get("adapters", {}), [name], "adapter")[name])
    adapter["name"] = name
    if parser:
        adapter["parser"] = parser
    return adapter


# ── one run ──────────────────────────────────────────────────────────────────

def sh(cmd: str, cwd: Path, env: dict | None = None, timeout: float | None = None):
    # stdin closed: `opencode run` otherwise waits on an open stdin forever (e58s02).
    return subprocess.run(["bash", "-c", cmd], cwd=cwd, env=env, stdin=subprocess.DEVNULL,
                          capture_output=True, text=True, timeout=timeout)


def git(workdir: Path, *args: str) -> str:
    res = subprocess.run(["git", *GIT_ID, *args], cwd=workdir, capture_output=True, text=True, check=True)
    return res.stdout.strip()


def snapshot(workdir: Path, message: str) -> str:
    git(workdir, "add", "-A")
    git(workdir, "commit", "-q", "--allow-empty", "--no-verify", "-m", message)
    return git(workdir, "rev-parse", "HEAD")


def file_lines(workdir: Path, paths: list[str]) -> dict:
    return {rel: (workdir / rel).read_text().splitlines() if (workdir / rel).is_file() else None
            for rel in paths}


def protected_changes(workdir: Path, before: dict) -> tuple[bool, int]:
    """Tampered = an original line removed or changed. Added lines are counted, not flagged:
    a TDD arm adds tests to the visible files, and hidden tests decide the grade (e58s02)."""
    tampered, added = False, 0
    for rel, now in file_lines(workdir, list(before)).items():
        if before[rel] is None or now is None:
            tampered = tampered or before[rel] is not None
            continue
        for op, _, _, j1, j2 in SequenceMatcher(None, before[rel], now, autojunk=False).get_opcodes():
            added += j2 - j1 if op == "insert" else 0
            tampered = tampered or op not in ("equal", "insert")
    return tampered, added


def changed_lines(workdir: Path, base: str) -> int:
    git(workdir, "add", "-A")
    total = 0
    for line in git(workdir, "diff", "--cached", "--numstat", base).splitlines():
        added, deleted, _ = line.split("\t", 2)
        total += (int(added) if added.isdigit() else 0) + (int(deleted) if deleted.isdigit() else 0)
    return total


def save_trace(path: Path, stdout: str) -> None:
    """Agent transcript for later process analysis (e58s05)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(gzip.compress(stdout.encode()))


def env_for(prompt: str, model: str | None, workdir: Path, home: Path, timeout_s: int = 900) -> dict:
    """$AB_HOME is a fresh empty dir per run: adapters point HOME at it to hide global skills.
    $AB_TIMEOUT leaves 30 s for an in-container `timeout` to stop the agent first (e58s07)."""
    env = dict(os.environ)
    env.update({"AB_PROMPT": prompt, "AB_MODEL": model or "", "AB_WORKDIR": str(workdir),
                "AB_HOME": str(home), "AB_BP_ROOT": str(REPO_ROOT), "AB_TIMEOUT": str(max(10, timeout_s - 30))})
    return env


def grade_cmd(adapter: dict, cmd: str, env: dict) -> tuple[str, dict]:
    """Runs grade/score through the adapter's grade_wrapper (e.g. a no-network container)."""
    if not adapter.get("grade_wrapper"):
        return cmd, env
    return adapter["grade_wrapper"], {**env, "AB_CMD": cmd}


def run_once(task: dict, arm: str, setup: str, adapter: dict, model: str | None,
             run_idx: int, keep: bool, trace_dir: Path | None = None) -> dict:
    workdir = Path(tempfile.mkdtemp(prefix=f"bp-ab-{task['id']}-{arm}-"))
    home = Path(tempfile.mkdtemp(prefix="bp-ab-home-"))
    try:
        shutil.copytree(task["dir"] / "fixture", workdir, dirs_exist_ok=True)
        git(workdir, "init", "-q")
        snapshot(workdir, "fixture")
        env = env_for(task["prompt"], model, workdir, home, task.get("timeout_s", 900))
        if sh(setup, workdir, env).returncode != 0:
            raise ConfigError(f"arm '{arm}' setup failed in {workdir}")
        base = snapshot(workdir, f"arm {arm}")
        protected = task.get("protected", [])
        before = file_lines(workdir, protected)

        started = time.monotonic()
        timed_out = False
        try:
            agent = sh(adapter["command"], workdir, env, timeout=task.get("timeout_s", 900))
            exit_code, stdout = agent.returncode, agent.stdout
        except subprocess.TimeoutExpired as exc:
            timed_out, exit_code = True, None
            stdout = exc.stdout.decode() if isinstance(exc.stdout, bytes) else (exc.stdout or "")
        duration = round(time.monotonic() - started, 1)
        if trace_dir is not None:
            save_trace(trace_dir / f"{task['id']}-{arm}-{run_idx}.jsonl.gz", stdout)

        tampered, protected_added = protected_changes(workdir, before)
        diff = changed_lines(workdir, base)
        shutil.copytree(task["dir"] / "hidden", workdir, dirs_exist_ok=True)
        cmd, genv = grade_cmd(adapter, task["grade"], env)
        passed = sh(cmd, workdir, genv, timeout=300).returncode == 0
        score = None
        if task.get("score"):
            cmd, genv = grade_cmd(adapter, task["score"], env)
            score = tap_score(sh(cmd, workdir, genv, timeout=300).stdout)
        bugs_opened = 0
        bug_details = []
        if task.get("audit"):
            if (task["dir"] / "audit").is_dir():
                shutil.copytree(task["dir"] / "audit", workdir, dirs_exist_ok=True)
            cmd, genv = grade_cmd(adapter, task["audit"], env)
            out = sh(cmd, workdir, genv, timeout=300).stdout
            bugs_opened = tap_failures(out)
            bug_details = tap_failed_names(out)
        metrics = parse_metrics(adapter.get("parser", "none"), stdout)
        return {
            "task": task["id"], "arm": arm, "run": run_idx, "pass": passed, "score": score,
            "bugs_opened": bugs_opened, "bug_details": bug_details, "tampered": tampered,
            "protected_lines_added": protected_added, "diff_lines": diff, "duration_s": duration, "agent_exit": exit_code,
            "agent_error": timed_out or exit_code != 0 or bool(metrics.pop("agent_reported_error")),
            "timed_out": timed_out, **metrics,
        }
    finally:
        shutil.rmtree(home, ignore_errors=True)
        if keep:
            print(f"  kept workdir: {workdir}")
        else:
            shutil.rmtree(workdir, ignore_errors=True)


# ── CLI ──────────────────────────────────────────────────────────────────────

def parse_args(argv: list[str] | None) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="A/B eval: vanilla agent vs bigpowers, outcome-graded")
    p.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    p.add_argument("--tasks-dir", type=Path, default=DEFAULT_TASKS_DIR)
    p.add_argument("--tasks", help="comma-separated task ids (default: all)")
    p.add_argument("--arms", default=DEFAULT_ARMS)
    p.add_argument("--k", type=int, help="runs per task per arm (default: config k)")
    p.add_argument("--adapter", help="adapter name (default: config default_adapter, else claude)")
    p.add_argument("--adapter-cmd", help="custom adapter command; prompt is in $AB_PROMPT")
    p.add_argument("--parser", help="output parser: claude-json | none")
    p.add_argument("--model", help="exported as $AB_MODEL for the adapter")
    p.add_argument("--out", type=Path, default=DEFAULT_OUT)
    p.add_argument("--keep", action="store_true", help="keep workdirs for inspection")
    p.add_argument("--dry-run", action="store_true", help="print the run matrix; run nothing")
    return p.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        config = load_yaml(args.config)
        arm_names = [a.strip() for a in args.arms.split(",") if a.strip()]
        arms = pick(config.get("arms", {}), arm_names, "arm")
        adapter_name = args.adapter or config.get("default_adapter", "claude")
        adapter = resolve_adapter(config, adapter_name, args.adapter_cmd, args.parser)
        tasks = load_tasks(args.tasks_dir, args.tasks.split(",") if args.tasks else None)
        if not tasks:
            raise ConfigError(f"no tasks found in {args.tasks_dir}")
    except ConfigError as exc:
        print(f"ERROR: {exc}")
        return 2
    k = args.k or int(config.get("k", 3))
    model = args.model or adapter.get("default_model")

    print(f"A/B eval: {len(tasks)} task(s) x {len(arms)} arm(s) x k={k} via adapter '{adapter['name']}'"
          f"{f' model {model}' if model else ''}")
    if args.dry_run:
        for task in tasks:
            for arm, spec in arms.items():
                print(f"  {task['id']:<8} {arm:<10} setup: {spec['setup']}")
        print(f"  adapter command: {adapter['command']}")
        return 0

    # Round-robin (e58s05): any prefix of the run covers every arm, and slow provider periods hit
    # all arms alike. Each record is appended to ab-live.jsonl as soon as its run finishes.
    records = []
    sha = bigpowers_sha()
    args.out.mkdir(parents=True, exist_ok=True)
    live = args.out / "ab-live.jsonl"
    try:
        for i in range(1, k + 1):
            for task in tasks:
                for arm, spec in arms.items():
                    rec = run_once(task, arm, spec["setup"], adapter, model, i, args.keep, args.out / "traces")
                    records.append(rec)
                    with live.open("a") as f:
                        f.write(json.dumps({**rec, "bigpowers_sha": sha, "model": model}) + "\n")
                    print(f"  {task['id']:<8} {arm:<10} run {i}: {'PASS' if rec['pass'] else 'FAIL'}"
                          f"{' TAMPERED' if rec['tampered'] else ''}{' AGENT-ERROR' if rec['agent_error'] else ''}")
    except ConfigError as exc:
        print(f"ERROR: {exc}")
        return 2

    result = aggregate(records, list(arms), [t["id"] for t in tasks])
    meta = {
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "bigpowers_sha": sha, "adapter": adapter["name"], "model": model,
        "k": k, "tasks": [t["id"] for t in tasks], "arms": list(arms),
        "arm_setup": {a: s["setup"] for a, s in arms.items()},
        "ci_method": f"bootstrap over runs, {BOOTSTRAP_RESAMPLES} resamples, seed {BOOTSTRAP_SEED}",
    }
    report = write_reports(args.out, meta, result, records)
    print_summary(result)
    print(f"Wrote {report}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
