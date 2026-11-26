# story: e54s02
# story: e83s04
# check-catalog-drift.py — logic for check-catalog-drift.sh (kept out of a heredoc: see e83s04)
import sys, glob, os, re
import yaml

baseline_path, skills_root = sys.argv[1], sys.argv[2]
baseline = yaml.safe_load(open(baseline_path)) or {}
base_by_name = {s["name"]: s for s in baseline.get("skills") or []}

EXCEPTION_MARKER = "freeze-exception"

def has_exception(skill_md):
    if not os.path.isfile(skill_md):
        return False
    with open(skill_md, encoding="utf-8") as f:
        return EXCEPTION_MARKER in f.read()

def parse_live(skill_md):
    text = open(skill_md, encoding="utf-8").read()
    fm = re.search(r"^---\n(.*?)\n---", text, re.S | re.M)
    fields = {}
    if fm:
        for line in fm.group(1).splitlines():
            m = re.match(r"^(phase|effort|model):\s*(.+)$", line)
            if m:
                fields[m.group(1)] = m.group(2).strip()
    return fields

live_by_name = {}
for skill_md in sorted(glob.glob(os.path.join(skills_root, "*", "SKILL.md"))):
    name = os.path.basename(os.path.dirname(skill_md))
    live_by_name[name] = {"path": skill_md, **parse_live(skill_md)}

warnings = []

for name, live in live_by_name.items():
    if name not in base_by_name:
        if not has_exception(live["path"]):
            warnings.append(f"WARNING: addition — new skill '{name}' not in frozen baseline")
        continue
    base = base_by_name[name]
    for field in ("phase", "effort", "model"):
        base_val = base.get(field)
        base_val = None if base_val in ("null", None) else str(base_val)
        live_val = live.get(field)
        if base_val != live_val:
            if not has_exception(live["path"]):
                warnings.append(
                    f"WARNING: structural change — '{name}' field '{field}' "
                    f"changed from {base_val!r} to {live_val!r}"
                )

for name, base in base_by_name.items():
    if name not in live_by_name:
        warnings.append(f"WARNING: removal — skill '{name}' present in baseline but missing from live catalog")

for w in warnings:
    print(w)
