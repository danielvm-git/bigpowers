#!/usr/bin/env python3
"""YAML helpers for bigpowers specs.

BUG-2026-07-03-yaml-roundtrip-corruption: this used to hand-roll a
"_parse_simple_yaml" reader with no concept of YAML lists or block
scalars, and re-serialize with a matching hand-rolled dumper. Any file
with a `- item` sequence (every epics[] list, every stories[] list) or
a block scalar (`note: >`) got silently flattened and destroyed on the
very first `set` call. It now uses PyYAML's safe_load/safe_dump for a
real, information-preserving round trip.
"""
from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import yaml


def set_path(path: Path, dotted_key: str, value: str) -> None:
    """Surgically set one dotted-path key, preserving everything else in the file."""
    text = path.read_text(encoding="utf-8") if path.exists() else ""
    loaded: Any = yaml.safe_load(text) if text.strip() else {}
    data: dict[str, Any] = loaded if isinstance(loaded, dict) else {}

    parts = dotted_key.split(".")
    cur: Any = data
    for part in parts[:-1]:
        if part not in cur or not isinstance(cur[part], dict):
            cur[part] = {}
        cur = cur[part]
    last = parts[-1]

    if value.lower() in ("true", "false"):
        cur[last] = value.lower() == "true"
    else:
        try:
            cur[last] = int(value)
        except ValueError:
            try:
                cur[last] = float(value)
            except ValueError:
                cur[last] = value.strip('"').strip("'")

    path.parent.mkdir(parents=True, exist_ok=True)
    # sort_keys=False preserves author-intended ordering (e.g. epics[]
    # sequencing by WSJF priority) instead of alphabetizing every key.
    path.write_text(
        yaml.safe_dump(data, sort_keys=False, allow_unicode=True, width=100),
        encoding="utf-8",
    )


def validate_file(path: Path, required_keys: list[str]) -> list[str]:
    if not path.exists():
        return [f"missing: {path}"]
    try:
        data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    except yaml.YAMLError as e:
        return [f"{path}: PARSE ERROR: {str(e).splitlines()[0]}"]
    errors: list[str] = []
    for key in required_keys:
        parts = key.split(".")
        cur: Any = data
        for part in parts:
            if not isinstance(cur, dict) or part not in cur:
                errors.append(f"{path}: missing key '{key}'")
                break
            cur = cur[part]
    return errors


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: yaml-tools.py set <file> <dotted.key> <value>", file=sys.stderr)
        return 2
    cmd = sys.argv[1]
    if cmd == "set":
        _, _, file, key, val = sys.argv
        set_path(Path(file), key, val)
        return 0
    if cmd == "validate":
        root = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("specs")
        errors: list[str] = []
        errors += validate_file(root / "state.yaml", ["active_flow"])
        errors += validate_file(
            root / "release-plan.yaml", ["release", "release.version", "epics"]
        )
        errors += validate_file(
            root / "execution-status.yaml", ["development_status"]
        )
        if errors:
            for e in errors:
                print(e)
            return 1
        print("OK")
        return 0
    print(f"unknown command: {cmd}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
