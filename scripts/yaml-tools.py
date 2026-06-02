#!/usr/bin/env python3
"""Minimal YAML helpers for bigpowers specs (no external deps)."""
from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Any


def _parse_simple_yaml(text: str) -> dict[str, Any]:
    """Parse flat and one-level-nested YAML (no lists of objects)."""
    root: dict[str, Any] = {}
    stack: list[tuple[int, dict[str, Any]]] = [(0, root)]
    for raw in text.splitlines():
        if not raw.strip() or raw.strip().startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip())
        line = raw.strip()
        if ":" not in line:
            continue
        key, _, val = line.partition(":")
        key = key.strip()
        val = val.strip()
        while stack and indent < stack[-1][0]:
            stack.pop()
        cur = stack[-1][1]
        if val == "":
            nxt: dict[str, Any] = {}
            cur[key] = nxt
            stack.append((indent + 2, nxt))
        else:
            if val in ("true", "false"):
                cur[key] = val == "true"
            elif val.startswith('"') and val.endswith('"'):
                cur[key] = val[1:-1]
            elif val.startswith("'") and val.endswith("'"):
                cur[key] = val[1:-1]
            else:
                try:
                    if "." in val:
                        cur[key] = float(val)
                    else:
                        cur[key] = int(val)
                except ValueError:
                    cur[key] = val
    return root


def _dump_value(val: Any, indent: int) -> str:
    sp = " " * indent
    if isinstance(val, dict):
        lines = []
        for k, v in val.items():
            if isinstance(v, dict):
                lines.append(f"{sp}{k}:")
                lines.append(_dump_value(v, indent + 2).rstrip())
            elif isinstance(v, bool):
                lines.append(f"{sp}{k}: {'true' if v else 'false'}")
            elif isinstance(v, (int, float)):
                lines.append(f"{sp}{k}: {v}")
            else:
                s = str(v).replace('"', '\\"')
                lines.append(f'{sp}{k}: "{s}"')
        return "\n".join(lines) + "\n"
    return f"{sp}{val}\n"


def dump_yaml(data: dict[str, Any]) -> str:
    return _dump_value(data, 0)


def set_path(path: Path, dotted_key: str, value: str) -> None:
    text = path.read_text(encoding="utf-8") if path.exists() else ""
    data = _parse_simple_yaml(text) if text.strip() else {}
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
    path.write_text(dump_yaml(data), encoding="utf-8")


def validate_file(path: Path, required_keys: list[str]) -> list[str]:
    errors: list[str] = []
    if not path.exists():
        return [f"missing: {path}"]
    text = path.read_text(encoding="utf-8")
    data = _parse_simple_yaml(text)
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
