#!/usr/bin/env python3
# story: BUG-2026-07-26-story-verify-never-executed
"""Emit executable story-level verify directives from epic capsules.

Tier-2 half of the verify arc (GH #106). Tier 1 is SKILL.md -> verify:, run by
run-skill-verify.sh. This walks specs/epics/*/epic.yaml plus any
*-tasks.yaml siblings and prints one TSV record per story that declares a
verify command:

    <story_id>\t<source_path>\t<status>\t<verify_command>

Newlines inside a folded/literal YAML block are collapsed to single spaces so
each record stays on one line for the bash caller.
"""

import glob
import os
import sys

try:
    import yaml
except ImportError:  # pragma: no cover - resolved by scripts/lib/python-env.sh
    sys.exit("extract-story-verify: PyYAML missing — pip install -r requirements.txt")

FIELD_SEPARATOR = "\t"
UNKNOWN_STATUS = "unknown"


def _flatten(command):
    """Collapse a multi-line YAML scalar into one whitespace-normalized line."""
    return " ".join(str(command).split())


def _story_records(stories, source_path):
    """Yield (id, source, status, verify) for each story declaring a verify."""
    for story in stories or []:
        if not isinstance(story, dict):
            continue
        verify = story.get("verify")
        story_id = story.get("id")
        if not verify or not story_id:
            continue
        status = story.get("status") or UNKNOWN_STATUS
        yield (str(story_id), source_path, str(status), _flatten(verify))


def _load_yaml(path):
    """Parse a YAML file, reporting the offending path on failure."""
    with open(path, encoding="utf-8") as handle:
        try:
            return yaml.safe_load(handle)
        except yaml.YAMLError as exc:
            raise SystemExit(
                f"extract-story-verify: cannot parse {path}: {exc}\n"
                "  Expected valid YAML; fix the capsule before running the gate."
            )


def _tasks_records(tasks_path):
    """Extract verify records from a *-tasks.yaml, which nests under `tasks:`."""
    doc = _load_yaml(tasks_path)
    if not isinstance(doc, dict):
        return []
    story_id = doc.get("story") or doc.get("id")
    records = list(_story_records(doc.get("stories"), tasks_path))
    for task in doc.get("tasks") or []:
        if not isinstance(task, dict) or not task.get("verify"):
            continue
        task_id = task.get("id") or story_id
        if not task_id:
            continue
        status = task.get("status") or doc.get("status") or UNKNOWN_STATUS
        records.append(
            (str(task_id), tasks_path, str(status), _flatten(task["verify"]))
        )
    return records


def collect_records(repo_root):
    """Gather every story/task verify directive across all epic capsules."""
    records = []
    epic_glob = os.path.join(repo_root, "specs", "epics", "*", "epic.yaml")
    for epic_path in sorted(glob.glob(epic_glob)):
        doc = _load_yaml(epic_path)
        if isinstance(doc, dict):
            records.extend(_story_records(doc.get("stories"), epic_path))

    tasks_glob = os.path.join(repo_root, "specs", "epics", "*", "*-tasks.yaml")
    for tasks_path in sorted(glob.glob(tasks_glob)):
        records.extend(_tasks_records(tasks_path))
    return records


def main():
    repo_root = sys.argv[1] if len(sys.argv) > 1 else "."
    for record in collect_records(repo_root):
        rel = os.path.relpath(record[1], repo_root)
        print(FIELD_SEPARATOR.join([record[0], rel, record[2], record[3]]))


if __name__ == "__main__":
    main()
