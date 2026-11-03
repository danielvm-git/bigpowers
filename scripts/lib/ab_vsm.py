#!/usr/bin/env python3
# story: e58s08
"""Value stream map of one A/B run: credit each model turn's time, tokens and cost to the lean stage
of the action it takes (plan, design, build, test, deploy, maintain; wrap-up when it takes none).

Tools are only 1-3% of a run's time, so time is credited per turn, not per tool call. pi stamps an
assistant message when it starts, so a turn lasts until the next assistant message starts: the model
time plus the tools it ran.
Rules: specs/benchmarks/ab/vsm.yaml.

CLI: python3 scripts/lib/ab_vsm.py <trace.jsonl.gz>...   (one VSM line per saved transcript)
"""
from __future__ import annotations

import gzip
import json
import re
import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
RULES_PATH = REPO_ROOT / "specs" / "benchmarks" / "ab" / "vsm.yaml"
WRAP_UP = "wrap-up"


def load_rules(path: Path = RULES_PATH) -> dict:
    rules = yaml.safe_load(path.read_text())
    rules["compiled"] = [(r["stage"], re.compile(r["tools"]), re.compile(r["target"])) for r in rules["rules"]]
    return rules


def classify_call(tool: str, args: dict | None, rules: dict) -> str:
    args = args or {}
    target = str(args.get("command") or args.get("path") or args.get("file_path") or "")
    for stage, tools, pattern in rules["compiled"]:
        if tools.search(tool or "") and pattern.search(target):
            return stage
    return "design"


def turn_stage(message: dict, rules: dict) -> str:
    calls = [c for c in message.get("content") or [] if isinstance(c, dict) and c.get("type") == "toolCall"]
    stages = {classify_call(c.get("name", ""), c.get("arguments"), rules) for c in calls}
    return next((s for s in rules["turn_priority"] if s in stages), WRAP_UP)


def pi_messages(stdout: str) -> list[dict]:
    messages = []
    for line in stdout.splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(event, dict) and event.get("type") == "message_end":
            message = event.get("message") or {}
            if isinstance(message.get("timestamp"), (int, float)):
                messages.append(message)
    return messages


def vsm_from_pi(stdout: str, rules: dict) -> dict | None:
    messages = pi_messages(stdout)
    if not any(m.get("role") == "assistant" for m in messages):
        return None
    start = messages[0]["timestamp"]
    stages: dict[str, dict] = {}
    sequence, first_build = [], None
    turns = [m for m in messages if m.get("role") == "assistant"]
    for i, message in enumerate(turns):
        stage = turn_stage(message, rules)
        end = turns[i + 1]["timestamp"] if i + 1 < len(turns) else messages[-1]["timestamp"]
        usage = message.get("usage") or {}
        slot = stages.setdefault(stage, {"s": 0.0, "cost_usd": 0.0, "output_tokens": 0, "turns": 0})
        slot["s"] = round(slot["s"] + (end - message["timestamp"]) / 1000, 3)
        slot["cost_usd"] = round(slot["cost_usd"] + ((usage.get("cost") or {}).get("total") or 0), 6)
        slot["output_tokens"] += usage.get("output", 0)
        slot["turns"] += 1
        sequence.append(stage)
        if stage == "build" and first_build is None:
            first_build = round((message["timestamp"] - start) / 1000, 3)
    return {
        "lead_time_s": round((messages[-1]["timestamp"] - start) / 1000, 3),
        "time_to_first_build_s": first_build,
        "switches": sum(1 for a, b in zip(sequence, sequence[1:]) if a != b),
        "sequence": sequence,
        "stages": stages,
    }


def vsm_from(parser: str, stdout: str, rules: dict | None = None) -> dict | None:
    """vsm block for a run record; None when the adapter's transcript format is not supported."""
    if parser != "pi-json":
        return None
    return vsm_from_pi(stdout, rules or load_rules())


def describe(name: str, block: dict | None) -> str:
    if not block:
        return f"{name:<32} no VSM (unsupported or empty transcript)"
    lead = block["lead_time_s"] or 1
    parts = sorted(block["stages"].items(), key=lambda kv: -kv[1]["s"])
    shares = "  ".join(f"{stage} {v['s']:.0f}s {100 * v['s'] / lead:.0f}%" for stage, v in parts if v["turns"])
    return f"{name:<32} lead {block['lead_time_s']:6.1f}s  first build {block['time_to_first_build_s']}s  " \
           f"switches {block['switches']:>2}  | {shares}"


def main(argv: list[str]) -> int:
    if not argv:
        print("usage: python3 scripts/lib/ab_vsm.py <trace.jsonl.gz>...")
        return 2
    rules = load_rules()
    for name in argv:
        path = Path(name)
        text = gzip.decompress(path.read_bytes()).decode() if path.suffix == ".gz" else path.read_text()
        print(describe(path.name, vsm_from_pi(text, rules)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
