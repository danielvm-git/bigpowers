#!/usr/bin/env python3
# story: e58s01 e58s02 e58s03
"""A/B eval adapter output parsers: turn an agent CLI's stdout into cost, token and turn counts.

claude-json      one result object (claude -p --output-format json)
opencode-jsonl   one event per line (opencode run --format json); step_finish carries tokens + cost
none             no metrics

tap_score reads `node --test` summaries for a task's partial-credit score (e58s03).
"""
from __future__ import annotations

import json
import re


def empty_metrics() -> dict:
    return {"cost_usd": None, "input_tokens": None, "output_tokens": None, "turns": None,
            "models": None, "agent_reported_error": None}


def json_lines(stdout: str) -> list[dict]:
    events = []
    for line in stdout.strip().splitlines():
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(obj, dict):
            events.append(obj)
    return events


def parse_metrics(parser: str, stdout: str) -> dict:
    if parser == "claude-json":
        return parse_claude_json(stdout)
    if parser == "opencode-jsonl":
        return parse_opencode_jsonl(stdout)
    return empty_metrics()


def parse_claude_json(stdout: str) -> dict:
    metrics = empty_metrics()
    result = next((e for e in reversed(json_lines(stdout)) if "num_turns" in e), None)
    if result is None:
        return metrics
    input_tokens, output_tokens = token_totals(result)
    metrics.update({
        "cost_usd": result.get("total_cost_usd"),
        "input_tokens": input_tokens,
        "output_tokens": output_tokens,
        "turns": result.get("num_turns"),
        "models": sorted(result.get("modelUsage") or {}) or None,
        "agent_reported_error": bool(result.get("is_error")),
    })
    return metrics


def token_totals(result: dict) -> tuple[int | None, int | None]:
    """Whole-tree tokens from modelUsage (incl. subagents and cache), else main-loop usage."""
    per_model = [m for m in (result.get("modelUsage") or {}).values() if "inputTokens" in m]
    if per_model:
        inputs = sum(m.get("inputTokens", 0) + m.get("cacheReadInputTokens", 0)
                     + m.get("cacheCreationInputTokens", 0) for m in per_model)
        return inputs, sum(m.get("outputTokens", 0) for m in per_model)
    usage = result.get("usage") or {}
    if "input_tokens" not in usage:
        return None, usage.get("output_tokens")
    inputs = (usage["input_tokens"] + usage.get("cache_read_input_tokens", 0)
              + usage.get("cache_creation_input_tokens", 0))
    return inputs, usage.get("output_tokens")


def parse_opencode_jsonl(stdout: str) -> dict:
    """Sum step_finish parts: tokens = {input, output, reasoning, cache: {read, write}}, cost in USD."""
    metrics = empty_metrics()
    events = json_lines(stdout)
    steps = [(e.get("part") or {}) for e in events if e.get("type") == "step_finish"]
    errored = any(e.get("type") == "error" for e in events)
    if not steps:
        metrics["agent_reported_error"] = errored or None
        return metrics
    cost = inputs = outputs = 0.0
    for part in steps:
        tokens = part.get("tokens") or {}
        cache = tokens.get("cache") or {}
        cost += part.get("cost") or 0
        inputs += tokens.get("input", 0) + cache.get("read", 0) + cache.get("write", 0)
        outputs += tokens.get("output", 0) + tokens.get("reasoning", 0)
    metrics.update({"cost_usd": round(cost, 6), "input_tokens": int(inputs), "output_tokens": int(outputs),
                    "turns": len(steps), "agent_reported_error": errored})
    return metrics


def tap_score(stdout: str) -> float | None:
    """Share of tests passing over every TAP summary (`node --test --test-reporter=tap`: piped
    output is the spec reporter otherwise). Cancelled tests (timeouts) count as failed."""
    passed = sum(int(n) for n in re.findall(r"^# pass (\d+)", stdout, re.M))
    failed = sum(int(n) for n in re.findall(r"^# (?:fail|cancelled) (\d+)", stdout, re.M))
    return round(passed / (passed + failed), 4) if passed + failed else None
