#!/usr/bin/env bash
# sync-status-from-epics.sh — seed execution-status.yaml keys from epic shards
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
SPECS="$REPO_ROOT/specs"
OUT="$SPECS/execution-status.yaml"
EPICS="$SPECS/epics"

$PYTHON - "$EPICS" "$OUT" <<'PY'
import re
import sys
from pathlib import Path
import yaml


def _yaml_str(s: str) -> str:
    """Return a YAML-safe quoted string, using single quotes when needed."""
    if not s:
        return "''"
    if any(c in s for c in ":{}[]&*?|>-;!%@`,\"\n\t#'"):
        escaped = s.replace("'", "''")
        return f"'{escaped}'"
    if s.startswith(" ") or s.endswith(" ") or s[0] in "0123456789":
        escaped = s.replace("'", "''")
        return f"'{escaped}'"
    return s


def _yaml_val(v) -> str:
    """Return a YAML-safe scalar representation."""
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return str(v)
    return _yaml_str(str(v))


epics_dir = Path(sys.argv[1])
out = Path(sys.argv[2])
keys: dict[str, str] = {}

existing_path = epics_dir.parent / "execution-status.yaml"
if existing_path.exists():
    existing = existing_path.read_text(encoding="utf-8")
    for m in re.finditer(r"^  ([a-z0-9._-]+):[ \t]*(\S+)?[ \t]*$", existing, re.M):
        if m.group(2):
            keys[m.group(1)] = m.group(2)

# --- Parse release-plan.yaml for wsjf/tier per epic ---
rp_epics: dict[str, dict[str, object]] = {}
rp_path = epics_dir.parent / "release-plan.yaml"
if rp_path.exists():
    try:
        rp = yaml.safe_load(rp_path.read_text(encoding="utf-8"))
        for ep in (rp.get("epics") or []):
            eid = ep.get("id")
            if not eid:
                continue
            entry: dict[str, object] = {}
            if "wsjf" in ep:
                entry["wsjf"] = ep["wsjf"]
            if "tier" in ep:
                entry["tier"] = ep["tier"]
            rp_epics[eid] = entry
    except Exception:
        pass

# --- Collect all epic sources (capsule dirs + flat YAML) ---
epic_sources: list[tuple[str, Path]] = []
seen_eids: set[str] = set()

# Search roots: epics_dir itself, plus immediate subdirectories (e.g., archive/)
search_roots = [epics_dir] if epics_dir.is_dir() else []
for sub in sorted(epics_dir.iterdir()) if epics_dir.is_dir() else []:
    if sub.is_dir():
        search_roots.append(sub)

for root in search_roots:
    for capsule in sorted(root.glob("e*/")):
        ey = capsule / "epic.yaml"
        if ey.exists():
            try:
                ed = yaml.safe_load(ey.read_text(encoding="utf-8"))
                eid = ed.get("id")
                if eid and eid not in seen_eids:
                    epic_sources.append((eid, ey))
                    seen_eids.add(eid)
            except Exception:
                pass

    for epic_file in sorted(root.glob("e*.yaml")):
        if re.search(r"e\d+s\d+", epic_file.stem):
            continue
        try:
            ed = yaml.safe_load(epic_file.read_text(encoding="utf-8"))
            eid = ed.get("id")
            if eid and eid not in seen_eids:
                epic_sources.append((eid, epic_file))
                seen_eids.add(eid)
        except Exception:
            pass

# --- Build enriched epic + story data ---
epics_output: dict[str, dict[str, object]] = {}
stories_output: dict[str, dict[str, object]] = {}

risk_rank = {"P0": 4, "P1": 3, "P2": 2, "P3": 1}
sec_rank = {"high": 4, "medium": 3, "low": 2, "none": 1}

for eid, epic_path in sorted(epic_sources):
    try:
        ed = yaml.safe_load(epic_path.read_text(encoding="utf-8"))
    except Exception:
        continue
    keys.setdefault(eid, "backlog")

    title = ed.get("title", "")
    total_bcps = ed.get("total_bcps") or ed.get("bcps")

    epics_output[eid] = {
        "status": keys[eid],
        "title": title,
        "wsjf": rp_epics.get(eid, {}).get("wsjf"),
        "total_bcps": total_bcps,
    }
    if "tier" in rp_epics.get(eid, {}):
        epics_output[eid]["tier"] = rp_epics[eid]["tier"]

    capsule_dir = epic_path.parent
    stories = ed.get("stories") or []

    for story in stories:
        if not isinstance(story, dict):
            continue
        sid = story.get("id")
        if not sid or not re.match(r"^e\d+s\d+$", str(sid)):
            continue
        keys.setdefault(sid, "backlog")

        story_bcps = story.get("bcp") or story.get("bcps")
        stories_output[sid] = {
            "status": keys[sid],
            "title": story.get("title", ""),
            "bcps": story_bcps,
            "epic": eid,
            "tasks_total": 0,
            "tasks_passing": 0,
            "tasks_failing": 0,
            "risk_max": None,
            "security_max": None,
        }

        # Look for -tasks.yaml at capsule root
        tasks_file = None
        for pattern in [f"{sid}-tasks.yaml", f"{sid}*.yaml"]:
            for tf in sorted(capsule_dir.glob(pattern)):
                try:
                    tf_data = yaml.safe_load(tf.read_text(encoding="utf-8"))
                    if isinstance(tf_data, dict) and "tasks" in tf_data:
                        tasks_file = tf
                        break
                except Exception:
                    pass
            if tasks_file:
                break

        if tasks_file:
            try:
                tf_data = yaml.safe_load(tasks_file.read_text(encoding="utf-8"))
                tasks = tf_data.get("tasks") or []

                stories_output[sid]["tasks_total"] = len(tasks)
                passing = sum(
                    1 for t in tasks
                    if isinstance(t, dict) and t.get("status") in ("done", "passing")
                )
                failing = sum(
                    1 for t in tasks
                    if isinstance(t, dict) and t.get("status") == "failing"
                )
                stories_output[sid]["tasks_passing"] = passing
                stories_output[sid]["tasks_failing"] = failing

                # Risk max: check individual tasks + story-level
                max_risk_val = None
                max_risk_rank = 0
                for t in tasks:
                    tr = t.get("risk") if isinstance(t, dict) else None
                    if tr in risk_rank and risk_rank[tr] > max_risk_rank:
                        max_risk_rank = risk_rank[tr]
                        max_risk_val = tr
                sr = tf_data.get("risk")
                if sr in risk_rank and risk_rank[sr] > max_risk_rank:
                    max_risk_val = sr
                stories_output[sid]["risk_max"] = max_risk_val

                # Security max: check individual tasks + story-level
                max_sec_val = None
                max_sec_rank = 0
                for t in tasks:
                    ts = t.get("security") if isinstance(t, dict) else None
                    if ts in sec_rank and sec_rank[ts] > max_sec_rank:
                        max_sec_rank = sec_rank[ts]
                        max_sec_val = ts
                ss = tf_data.get("security")
                if ss in sec_rank and sec_rank[ss] > max_sec_rank:
                    max_sec_val = ss
                stories_output[sid]["security_max"] = max_sec_val

            except Exception:
                pass

    # Stories/ subdirectory (future-proofing)
    stories_dir = capsule_dir / "stories"
    if stories_dir.is_dir():
        for story_file in sorted(stories_dir.glob("e*s*.md")):
            m = re.match(r"(e\d+s\d+)", story_file.stem)
            if m:
                sid = m.group(1)
                keys.setdefault(sid, "backlog")
                if sid not in stories_output:
                    stories_output[sid] = {
                        "status": keys[sid],
                        "title": "",
                        "bcps": None,
                        "epic": eid,
                        "tasks_total": 0,
                        "tasks_passing": 0,
                        "tasks_failing": 0,
                        "risk_max": None,
                        "security_max": None,
                    }

# --- Build output ---
lines = ["development_status:"]
for k in sorted(keys.keys()):
    lines.append(f"  {k}: {keys[k]}")
lines.append("")

# --- Epics section ---
lines.append("epics:")
for eid in sorted(epics_output.keys()):
    lines.append(f"  {eid}:")
    ep = epics_output[eid]
    lines.append(f"    status: {_yaml_val(ep['status'])}")
    lines.append(f"    title: {_yaml_str(ep.get('title', ''))}")
    if ep.get("wsjf") is not None:
        lines.append(f"    wsjf: {ep['wsjf']}")
    if ep.get("tier") is not None:
        lines.append(f"    tier: {ep['tier']}")
    if ep.get("total_bcps") is not None:
        lines.append(f"    total_bcps: {ep['total_bcps']}")
lines.append("")

# --- Stories section ---
lines.append("stories:")
for sid in sorted(stories_output.keys()):
    lines.append(f"  {sid}:")
    st = stories_output[sid]
    lines.append(f"    status: {_yaml_val(st['status'])}")
    lines.append(f"    title: {_yaml_str(st.get('title', ''))}")
    if st.get("bcps") is not None:
        lines.append(f"    bcps: {st['bcps']}")
    lines.append(f"    epic: {_yaml_val(st['epic'])}")
    lines.append(f"    tasks_total: {st['tasks_total']}")
    lines.append(f"    tasks_passing: {st['tasks_passing']}")
    lines.append(f"    tasks_failing: {st['tasks_failing']}")
    if st.get("risk_max") is not None:
        lines.append(f"    risk_max: {_yaml_val(st['risk_max'])}")
    if st.get("security_max") is not None:
        lines.append(f"    security_max: {_yaml_val(st['security_max'])}")
lines.append("")

out.write_text("\n".join(lines), encoding="utf-8")
print(f"sync-status-from-epics: wrote {out} ({len(keys)} development keys, {len(epics_output)} epics, {len(stories_output)} stories)")
PY
