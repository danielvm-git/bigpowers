#!/usr/bin/env python3
# story: e58s10
"""Lean views of an A/B run: each arm's mean value stream (stage time and share) and waste metrics,
deltas against vanilla with seeded bootstrap CIs, and text VSM bars plus a waste table.

Reads the `vsm` (e58s08) and `waste` (e58s09) blocks of run records; runs without them are skipped.
"""
from __future__ import annotations

from ab_report import bootstrap_delta_ci, mean  # type: ignore[import]

STAGES = ["plan", "design", "build", "test", "deploy", "maintain"]
LETTER = {"plan": "P", "design": "D", "build": "B", "test": "T", "deploy": "R", "maintain": "M"}
WASTE_KEYS = ["test_runs", "redundant_test_runs", "rework_loops", "reedits", "rereads",
              "repeated_commands", "review_load", "diff_ratio", "pce"]
# (key, label, per-run extractor) for the deltas against vanilla.
DELTAS = [
    ("lead_time_s", "lead time (s)", lambda r: r["vsm"]["lead_time_s"]),
    ("time_to_first_build_s", "first build (s)", lambda r: r["vsm"]["time_to_first_build_s"]),
    ("switches", "stage switches", lambda r: r["vsm"]["switches"]),
    ("build_share", "build share", lambda r: share(r, "build")),
    ("test_share", "test share", lambda r: share(r, "test")),
    ("test_runs", "test runs", lambda r: r["waste"].get("test_runs")),
    ("redundant_test_runs", "redundant test runs", lambda r: r["waste"].get("redundant_test_runs")),
    ("rework_loops", "rework loops", lambda r: r["waste"].get("rework_loops")),
    ("reedits", "re-edits", lambda r: r["waste"].get("reedits")),
    ("review_load", "review load", lambda r: r["waste"].get("review_load")),
    ("diff_ratio", "diff ratio", lambda r: r["waste"].get("diff_ratio")),
    ("ftt", "first-time-through", lambda r: None if r["waste"].get("ftt") is None else float(r["waste"]["ftt"])),
    ("pce", "PCE", lambda r: r["waste"].get("pce")),
]


def share(run: dict, stage: str) -> float | None:
    lead = run["vsm"]["lead_time_s"]
    return run["vsm"]["stages"].get(stage, {}).get("s", 0) / lead if lead else None


def lean_runs(records: list[dict], arm: str) -> list[dict]:
    return [r for r in records if r["arm"] == arm and r.get("vsm") and r.get("waste")]


def arm_lean(runs: list[dict], all_runs: list[dict]) -> dict:
    passes = sum(r["pass"] for r in all_runs)
    cost = sum(r.get("cost_usd") or 0 for r in all_runs)
    return {
        "runs": len(runs),
        "lead_time_s": mean([r["vsm"]["lead_time_s"] for r in runs]),
        "time_to_first_build_s": mean([r["vsm"]["time_to_first_build_s"] for r in runs]),
        "switches": mean([r["vsm"]["switches"] for r in runs]),
        "stage_s": {s: mean([r["vsm"]["stages"].get(s, {}).get("s", 0) for r in runs]) for s in STAGES},
        "stage_share": {s: mean([share(r, s) for r in runs]) for s in STAGES},
        "waste": {k: mean([r["waste"].get(k) for r in runs]) for k in WASTE_KEYS},
        "ftt_rate": mean([None if r["waste"].get("ftt") is None else float(r["waste"]["ftt"]) for r in runs]),
        "leftover_rate": mean([float(bool(r["waste"].get("leftovers"))) for r in runs]),
        "cost_per_pass": round(cost / passes, 6) if passes else None,
    }


def lean_summary(records: list[dict], arms: list[str]) -> dict | None:
    by_arm = {a: lean_runs(records, a) for a in arms}
    if not any(by_arm.values()):
        return None
    summary = {a: arm_lean(runs, [r for r in records if r["arm"] == a]) for a, runs in by_arm.items() if runs}
    deltas = {}
    if "vanilla" in summary:
        for arm in summary:
            if arm == "vanilla":
                continue
            deltas[arm] = {}
            for key, _, get in DELTAS:
                tr = [v for v in map(get, by_arm[arm]) if v is not None]
                va = [v for v in map(get, by_arm["vanilla"]) if v is not None]
                if tr and va:
                    deltas[arm][key] = {"delta": round(sum(tr) / len(tr) - sum(va) / len(va), 4),
                                        "ci95": bootstrap_delta_ci(tr, va)}
    return {"arms": summary, "deltas": deltas}


def bar(arm: dict, scale: float) -> str:
    """Stage letters, one per `scale` seconds of mean stage time: the bar's length is the lead time."""
    return "".join(LETTER[s] * round((arm["stage_s"][s] or 0) / scale) for s in STAGES)


def fmt(value, places=2) -> str:
    return "-" if value is None else f"{value:.{places}f}"


def lean_lines(summary: dict | None, width: int = 50) -> list[str]:
    if not summary:
        return []
    arms = summary["arms"]
    scale = max((a["lead_time_s"] or 0) for a in arms.values()) / width or 1
    out = ["", "value stream (bar length = mean lead time; P plan, D design, B build, T test, R release, M maintain):"]
    for name, a in arms.items():
        out.append(f"  {name:<10} |{bar(a, scale):<{width}}| {fmt(a['lead_time_s'], 0):>5} s  "
                   f"first build {fmt(a['time_to_first_build_s'], 0)} s  PCE {fmt(a['waste']['pce'])}  "
                   f"FTT {fmt(a['ftt_rate'])}  $/pass {fmt(a['cost_per_pass'], 4)}")
    out += ["", f"  {'waste (mean per run)':<22}" + "".join(f"{n:>11}" for n in arms) + "   delta vs vanilla [95% CI]"]
    for key, label, _ in DELTAS:
        if key in ("lead_time_s", "time_to_first_build_s"):
            continue
        values = "".join(f"{fmt(row_value(a, key)):>11}" for a in arms.values())
        ds = "  ".join(f"{n} {d[key]['delta']:+.2f} {d[key]['ci95']}" for n, d in summary["deltas"].items() if key in d)
        out.append(f"  {label:<22}{values}   {ds}")
    return out


def row_value(arm: dict, key: str):
    if key == "switches":
        return arm["switches"]
    if key in ("build_share", "test_share"):
        return arm["stage_share"][key.split("_")[0]]
    if key == "ftt":
        return arm["ftt_rate"]
    return arm["waste"].get(key)
