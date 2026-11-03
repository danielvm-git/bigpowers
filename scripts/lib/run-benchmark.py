#!/usr/bin/env python3
# story: e45s01
"""Run skill benchmarks from specs/benchmarks/ with train/validation split and delta grading."""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import date
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from atomic_write import atomic_write_text  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[2]
BENCH_DIR = REPO_ROOT / "specs" / "benchmarks"
REPORTS_DIR = BENCH_DIR / "reports"
DEFAULT_RUNS = 3
GRADER_TIMEOUT = 15


def load_definition(skill: str) -> dict:
    path = BENCH_DIR / f"{skill}.yaml"
    if not path.exists():
        print(f"ERROR: no benchmark definition at {path}", file=sys.stderr)
        sys.exit(1)
    with path.open() as f:
        return yaml.safe_load(f)


def list_skills() -> list[str]:
    return sorted(p.stem for p in BENCH_DIR.glob("*.yaml") if p.stem not in ("axes",))


def run_code_grader(command: str, cwd: Path) -> bool:
    try:
        result = subprocess.run(
            ["bash", "-c", command],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=GRADER_TIMEOUT,
        )
        out = (result.stdout + result.stderr).strip()
        if "PASS" in out.upper() and "FAIL" not in out.upper():
            return True
        return result.returncode == 0
    except (subprocess.TimeoutExpired, OSError):
        return False


def scenario_pass_rate(scenario: dict, runs: int, with_skill: bool) -> tuple[float, str]:
    grader = scenario.get("grader", {})
    gtype = grader.get("type", "code")
    if gtype == "rubric":
        return (-1.0, "pending_agent_eval")
    if gtype != "code":
        return (-1.0, "unsupported_grader")
    command = grader.get("command", "")
    if not command:
        return (-1.0, "missing_command")
    if not with_skill:
        # No agent runs here, so there is no honest without-skill number (e58s01).
        # Real with/without deltas come from scripts/run-ab-eval.sh.
        return (-1.0, "unmeasured")
    passes = sum(1 for _ in range(runs) if run_code_grader(command, REPO_ROOT))
    return (passes / runs, "code")


def pass_at_k(scenarios: list[dict], runs: int, with_skill: bool) -> float | None:
    total_weight = 0.0
    weighted = 0.0
    for sc in scenarios:
        rate, status = scenario_pass_rate(sc, runs, with_skill)
        if status in ("pending_agent_eval", "unmeasured"):
            continue
        weight = float(sc.get("weight", 1.0))
        total_weight += weight
        weighted += weight * max(rate, 0.0)
    if total_weight == 0:
        return None
    return round(weighted / total_weight, 2)


def delta_of(with_score: float | None, without_score: float | None) -> float | None:
    if with_score is None or without_score is None:
        return None
    return round(with_score - without_score, 2)


def delta_summary(val_delta: float | None) -> str:
    if val_delta is None:
        return "UNMEASURED: no without-skill agent run — use scripts/run-ab-eval.sh for a real delta"
    if val_delta < 0:
        return f"REGRESSION: validation Δ {val_delta} — do NOT ship"
    if val_delta < 0.05:
        return f"WARN: validation Δ {val_delta} — marginal contribution"
    return f"OK: validation Δ {val_delta}"


def partition_scenarios(scenarios: list[dict]) -> tuple[list[dict], list[dict]]:
    train, validation = [], []
    for sc in scenarios:
        split = sc.get("split", "validation")
        if split == "train":
            train.append(sc)
        else:
            validation.append(sc)
    return train, validation


def build_split_report(scenarios: list[dict], runs: int) -> dict:
    if not scenarios:
        return {"with_skill": None, "without_skill": None, "delta": None, "scenarios": []}
    with_score = pass_at_k(scenarios, runs, with_skill=True)
    without_score = pass_at_k(scenarios, runs, with_skill=False)
    return {
        "with_skill": with_score,
        "without_skill": without_score,
        "delta": delta_of(with_score, without_score),
        "scenarios": [sc["id"] for sc in scenarios],
    }


def scenario_details(scenarios: list[dict], runs: int) -> list[dict]:
    rows = []
    for sc in scenarios:
        with_rate, status = scenario_pass_rate(sc, runs, with_skill=True)
        without_rate, _ = scenario_pass_rate(sc, runs, with_skill=False)
        if status == "pending_agent_eval":
            rows.append(
                {
                    "id": sc["id"],
                    "split": sc.get("split", "validation"),
                    "status": "pending_agent_eval",
                    "weight": sc.get("weight", 1.0),
                }
            )
            continue
        with_value = round(max(with_rate, 0.0), 2)
        without_value = None if without_rate < 0 else round(without_rate, 2)
        rows.append(
            {
                "id": sc["id"],
                "split": sc.get("split", "validation"),
                "with_pass_rate": with_value,
                "without_pass_rate": without_value,
                "delta": delta_of(with_value, without_value),
                "weight": sc.get("weight", 1.0),
            }
        )
    return rows


def run_benchmark(skill: str, baseline: bool = False) -> dict:
    definition = load_definition(skill)
    runs = int(definition.get("runs", DEFAULT_RUNS))
    scenarios = definition.get("scenarios", [])
    train_sc, val_sc = partition_scenarios(scenarios)
    today = date.today().isoformat()
    report = {
        "skill": skill,
        "run_date": today,
        "runs_per_scenario": runs,
        "train": build_split_report(train_sc, runs),
        "validation": build_split_report(val_sc, runs),
        "scenarios": scenario_details(scenarios, runs),
    }
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    yaml_path = REPORTS_DIR / f"BENCHMARK-{skill}-{today}.yaml"
    json_path = REPORTS_DIR / f"benchmark-{skill}.json"
    yaml_text = yaml.dump(
            {
                "skill": skill,
                "run_date": today,
                "runs_per_scenario": runs,
                "train": {
                    "pass_at_k_with": report["train"]["with_skill"],
                    "pass_at_k_without": report["train"]["without_skill"],
                    "delta": report["train"]["delta"],
                },
                "validation": {
                    "pass_at_k_with": report["validation"]["with_skill"],
                    "pass_at_k_without": report["validation"]["without_skill"],
                    "delta": report["validation"]["delta"],
                },
                "scenarios": report["scenarios"],
            },
            f,
            default_flow_style=False,
    )
    atomic_write_text(yaml_path, yaml_text)
    atomic_write_text(json_path, json.dumps(report, separators=(",", ":")))
    print(f"Wrote {yaml_path}")
    print(f"Wrote {json_path}")
    if baseline:
        import shutil

        shutil.copy(yaml_path, REPORTS_DIR / f"BASELINE-{skill}.yaml")
        shutil.copy(json_path, REPORTS_DIR / f"baseline-{skill}.json")
        print(f"Pinned baseline for {skill}")
    print(delta_summary(report["validation"]["delta"]))
    return report


def main() -> None:
    parser = argparse.ArgumentParser(description="Run skill quality benchmarks")
    parser.add_argument("skill", nargs="?", help="Skill name to benchmark")
    parser.add_argument("--all", action="store_true", help="Benchmark all skills with definitions")
    parser.add_argument("--baseline", action="store_true", help="Pin results as baseline")
    args = parser.parse_args()
    if args.all:
        for skill in list_skills():
            run_benchmark(skill, baseline=args.baseline)
    elif args.skill:
        run_benchmark(args.skill, baseline=args.baseline)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
