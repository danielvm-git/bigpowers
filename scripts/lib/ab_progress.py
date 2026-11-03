#!/usr/bin/env python3
# story: e58s05
"""Live view of an A/B eval while it runs: reads every ab-live.jsonl under the given folders
(one per shard) and prints runs, pass rate, score and cost per task and arm, each arm's delta
against vanilla with its bootstrap CI, and how those deltas evolved as runs accumulated.

Usage: python3 scripts/lib/ab_progress.py <out-dir>... [--watch SECONDS]
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ab_report import aggregate, mean  # type: ignore[import]  # noqa: E402

CHECKPOINTS = (5, 10, 20, 30, 50, 75, 100)


def load(dirs: list[Path]) -> list[dict]:
    records = []
    for folder in dirs:
        for live in sorted(folder.rglob("ab-live.jsonl")):
            records += [json.loads(line) for line in live.read_text().splitlines() if line.strip()]
    return records


def ordered(values: list[str], preferred: str) -> list[str]:
    unique = sorted(set(values))
    return [preferred] + [v for v in unique if v != preferred] if preferred in unique else unique


def fmt(value, places=2) -> str:
    return "-" if value is None else f"{value:.{places}f}"


def table(records: list[dict], tasks: list[str], arms: list[str]) -> list[str]:
    lines = [f"{'task':<8} {'arm':<10} {'runs':>5} {'pass':>6} {'score':>6} {'cost$':>7} {'errors':>6}"]
    for task in tasks:
        for arm in arms:
            runs = [r for r in records if r["task"] == task and r["arm"] == arm]
            if runs:
                lines.append(f"{task:<8} {arm:<10} {len(runs):>5} {fmt(mean([float(r['pass']) for r in runs])):>6} "
                             f"{fmt(mean([r.get('score') for r in runs])):>6} {fmt(mean([r['cost_usd'] for r in runs]), 3):>7} "
                             f"{sum(r['agent_error'] for r in runs):>6}")
    return lines


def delta_line(name: str, d: dict) -> str:
    line = f"  {name} - vanilla: pass {d['pass_rate']:+.2f} {d['ci95']}"
    if "score" in d:
        line += f"  score {d['score']:+.3f} {d['score_ci95']}"
    return line


def evolution(records: list[dict], tasks: list[str], arms: list[str]) -> list[str]:
    """Deltas using only runs with index <= each checkpoint: shows the CI narrowing over time."""
    top = max(r["run"] for r in records)
    lines = []
    for cp in [c for c in CHECKPOINTS if c < top] + [top]:
        subset = [r for r in records if r["run"] <= cp]
        for name, d in aggregate(subset, arms, tasks)["deltas_vs_vanilla"].items():
            lines.append(f"  runs<={cp:<4}{delta_line(name, d)[1:]}")
    return lines


def render(records: list[dict]) -> str:
    tasks = sorted({r["task"] for r in records})
    arms = ordered([r["arm"] for r in records], "vanilla")
    models = sorted({str(r.get("model")) for r in records})
    out = [f"A/B progress — {len(records)} runs, model {', '.join(models)}, at {datetime.now():%H:%M:%S}", ""]
    out += table(records, tasks, arms)
    result = aggregate(records, arms, tasks)
    if result["deltas_vs_vanilla"]:
        out += ["", "deltas (all runs so far, 95% CI):"]
        out += [delta_line(n, d) for n, d in result["deltas_vs_vanilla"].items()]
        out += ["", "evolution (pass and score delta by run index):"] + evolution(records, tasks, arms)
    return "\n".join(out)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Live A/B eval progress across shards")
    p.add_argument("dirs", nargs="+", type=Path)
    p.add_argument("--watch", type=int, help="repeat every N seconds")
    args = p.parse_args(argv)
    while True:
        records = load(args.dirs)
        if not records:
            print("no ab-live.jsonl found under: " + ", ".join(map(str, args.dirs)))
            return 2
        print(render(records), flush=True)
        if not args.watch:
            return 0
        time.sleep(args.watch)
        print()


if __name__ == "__main__":
    sys.exit(main())
