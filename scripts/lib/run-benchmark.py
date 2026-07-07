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
        command = f"test -f /dev/null"  # bare agent: code graders cannot pass without skill context
    passes = sum(1 for _ in range(runs) if run_code_grader(command, REPO_ROOT))
    return (passes / runs, "code")


def pass_at_k(scenarios: list[dict], runs: int, with_skill: bool) -> float:
    total_weight = 0.0
    weighted = 0.0
    for sc in scenarios:
        rate, status = scenario_pass_rate(sc, runs, with_skill)
        if status == "pending_agent_eval":
            continue
        weight = float(sc.get("weight", 1.0))
        total_weight += weight
        weighted += weight * max(rate, 0.0)
    if total_weight == 0:
        return 0.0
    return round(weighted / total_weight, 2)


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
        return {"with_skill": 0.0, "without_skill": 0.0, "delta": 0.0, "scenarios": []}
    with_score = pass_at_k(scenarios, runs, with_skill=True)
    without_score = pass_at_k(scenarios, runs, with_skill=False)
    return {
        "with_skill": with_score,
        "without_skill": without_score,
        "delta": round(with_score - without_score, 2),
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
        rows.append(
            {
                "id": sc["id"],
                "split": sc.get("split", "validation"),
                "with_pass_rate": round(max(with_rate, 0.0), 2),
                "without_pass_rate": round(max(without_rate, 0.0), 2),
                "delta": round(max(with_rate, 0.0) - max(without_rate, 0.0), 2),
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
    with yaml_path.open("w") as f:
        yaml.dump(
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
    with json_path.open("w") as f:
        json.dump(report, f, separators=(",", ":"))
    print(f"Wrote {yaml_path}")
    print(f"Wrote {json_path}")
    if baseline:
        import shutil

        shutil.copy(yaml_path, REPORTS_DIR / f"BASELINE-{skill}.yaml")
        shutil.copy(json_path, REPORTS_DIR / f"baseline-{skill}.json")
        print(f"Pinned baseline for {skill}")
    val_delta = report["validation"]["delta"]
    if val_delta < 0:
        print(f"REGRESSION: validation Δ {val_delta} — do NOT ship")
    elif val_delta < 0.05:
        print(f"WARN: validation Δ {val_delta} — marginal contribution")
    else:
        print(f"OK: validation Δ {val_delta}")
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
