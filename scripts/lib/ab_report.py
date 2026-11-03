#!/usr/bin/env python3
# story: e58s01 e58s03 e58s04
"""A/B eval aggregation and reports — pure functions over run records (no agent, no subprocess
except reading the bigpowers git SHA). Split from ab-eval.py to keep both under the 300-line cap."""
from __future__ import annotations

import json
import random
import subprocess
from datetime import date
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
BOOTSTRAP_RESAMPLES = 1000
BOOTSTRAP_SEED = 58


# ── aggregation ──────────────────────────────────────────────────────────────

def mean(values: list) -> float | None:
    vals = [v for v in values if v is not None]
    return round(sum(vals) / len(vals), 4) if vals else None


def bootstrap_delta_ci(treatment: list[float], control: list[float]) -> list[float]:
    """Seeded 95% CI of mean(treatment) - mean(control); bools or scores in [0, 1]."""
    rng = random.Random(BOOTSTRAP_SEED)
    deltas = []
    for _ in range(BOOTSTRAP_RESAMPLES):
        t = [rng.choice(treatment) for _ in treatment]
        c = [rng.choice(control) for _ in control]
        deltas.append(sum(t) / len(t) - sum(c) / len(c))
    deltas.sort()
    lo = deltas[int(0.025 * BOOTSTRAP_RESAMPLES)]
    hi = deltas[int(0.975 * BOOTSTRAP_RESAMPLES) - 1]
    return [round(lo, 4), round(hi, 4)]


def arm_summary(runs: list[dict]) -> dict:
    return {
        "runs": len(runs),
        "pass_rate": mean([float(r["pass"]) for r in runs]),
        "mean_score": mean([r.get("score") for r in runs]),
        "mean_bugs_opened": mean([r.get("bugs_opened", 0) for r in runs]),
        "tamper_rate": mean([float(r["tampered"]) for r in runs]),
        "agent_error_rate": mean([float(r["agent_error"]) for r in runs]),
        "mean_cost_usd": mean([r["cost_usd"] for r in runs]),
        "mean_input_tokens": mean([r["input_tokens"] for r in runs]),
        "mean_output_tokens": mean([r["output_tokens"] for r in runs]),
        "mean_turns": mean([r["turns"] for r in runs]),
        "mean_duration_s": mean([r["duration_s"] for r in runs]),
        "mean_diff_lines": mean([r["diff_lines"] for r in runs]),
    }


def aggregate(records: list[dict], arms: list[str], tasks: list[str]) -> dict:
    by_arm = {a: [r for r in records if r["arm"] == a] for a in arms}
    summary = {a: arm_summary(runs) for a, runs in by_arm.items()}
    per_task = {t: {a: mean([float(r["pass"]) for r in by_arm[a] if r["task"] == t]) for a in arms}
                for t in tasks}
    per_task_score = {t: {a: mean([r.get("score") for r in by_arm[a] if r["task"] == t]) for a in arms}
                      for t in tasks}
    deltas = {a: arm_delta(by_arm, summary, a) for a in arms if a != "vanilla"} if "vanilla" in arms else {}
    return {"arms_summary": summary, "per_task": per_task, "per_task_score": per_task_score,
            "delta": deltas.get("bigpowers"), "deltas_vs_vanilla": deltas}


def arm_delta(by_arm: dict, summary: dict, arm: str) -> dict:
    """arm - vanilla: pass rate and score with seeded bootstrap CIs, tamper rate and cost (e58s04)."""
    tr, va = summary[arm], summary["vanilla"]
    cost = None
    if tr["mean_cost_usd"] is not None and va["mean_cost_usd"] is not None:
        cost = round(tr["mean_cost_usd"] - va["mean_cost_usd"], 4)
    delta = {
        "pass_rate": round(tr["pass_rate"] - va["pass_rate"], 4),
        "ci95": bootstrap_delta_ci([r["pass"] for r in by_arm[arm]], [r["pass"] for r in by_arm["vanilla"]]),
        "tamper_rate": round(tr["tamper_rate"] - va["tamper_rate"], 4),
        "cost_usd": cost,
    }
    scores = {a: [r["score"] for r in by_arm[a] if r.get("score") is not None] for a in (arm, "vanilla")}
    if scores[arm] and scores["vanilla"]:
        delta["score"] = round(tr["mean_score"] - va["mean_score"], 4)
        delta["score_ci95"] = bootstrap_delta_ci(scores[arm], scores["vanilla"])
    if tr.get("mean_bugs_opened") is not None and va.get("mean_bugs_opened") is not None:
        delta["bugs_opened"] = round(tr["mean_bugs_opened"] - va["mean_bugs_opened"], 4)
    return delta


# ── reporting ────────────────────────────────────────────────────────────────

def bigpowers_sha() -> str:
    res = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=REPO_ROOT, capture_output=True, text=True)
    return res.stdout.strip() or "unknown"


def write_reports(out: Path, meta: dict, result: dict, records: list[dict]) -> Path:
    out.mkdir(parents=True, exist_ok=True)
    today = date.today().isoformat()
    report = out / f"AB-{today}.yaml"
    report.write_text(yaml.safe_dump({**meta, **result}, sort_keys=False))
    with (out / f"ab-runs-{today}.jsonl").open("w") as f:
        for rec in records:
            f.write(json.dumps({**rec, "bigpowers_sha": meta["bigpowers_sha"]}) + "\n")
    return report


def print_summary(result: dict) -> None:
    print(f"{'arm':<10} {'pass':>6} {'score':>6} {'bugs':>6} {'tamper':>7} {'cost$':>8} {'turns':>6} {'secs':>7}")
    for arm, s in result["arms_summary"].items():
        fmt = lambda v, p=2: "-" if v is None else f"{v:.{p}f}"
        b_str = "-" if s.get("mean_bugs_opened") is None else f"{s['mean_bugs_opened']:.1f}"
        print(f"{arm:<10} {fmt(s['pass_rate']):>6} {fmt(s['mean_score']):>6} {b_str:>6} {fmt(s['tamper_rate']):>7} "
              f"{fmt(s['mean_cost_usd'], 3):>8} {fmt(s['mean_turns'], 1):>6} {fmt(s['mean_duration_s'], 0):>7}")
    for arm, d in result.get("deltas_vs_vanilla", {}).items():
        line = f"delta {arm:<10} - vanilla: pass {d['pass_rate']:+.2f} CI {d['ci95']}"
        if "score" in d:
            line += f"  score {d['score']:+.2f} CI {d['score_ci95']}"
        if "bugs_opened" in d:
            line += f"  bugs {d['bugs_opened']:+.1f}"
        print(line)
