#!/usr/bin/env python3
# story: e45s22
"""Apply Wave B install hub wiring for fleet integration epics."""
from __future__ import annotations

import sys
from pathlib import Path

_LIB = Path(__file__).resolve().parent / "lib"
if str(_LIB) not in sys.path:
    sys.path.insert(0, str(_LIB))

from wave_b_hub_patch import apply_epic  # noqa: E402
from wave_b_hub_config import HUB_EPICS  # noqa: E402

def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("Usage: generate-wave-b-hub.py <e65|e68|...|all>", file=sys.stderr)
        return 1
    target = argv[1]
    ids = list(HUB_EPICS.keys()) if target == "all" else [target]
    for eid in ids:
        if eid not in HUB_EPICS:
            print(f"Unknown epic: {eid}", file=sys.stderr)
            return 1
        apply_epic(eid)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
