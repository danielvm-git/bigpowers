#!/usr/bin/env python3
# story: e38s01
"""tests/test_trace_stories.py — regression tests for the traceability gate.

Run: python3 tests/test_trace_stories.py

The gate used to read story status from `development_status:` (phase metadata)
instead of `stories:`, so every story resolved to "backlog", `--strict` skipped
all of them as unimplemented, and the gate passed while verifying nothing. Each
test below builds a throw-away fixture repo and drives the real script, so the
tests fail against the old wrong-key read rather than asserting on internals.
"""
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPT = REPO_ROOT / "scripts" / "lib" / "trace-stories.py"

RELEASE_PLAN = """\
release:
  version: '9.9.9'
epics:
  - id: 'e01'
    title: 'Fixture epic'
    wsjf: 10
    bcps: 3
    capsule_dir: 'epics/e01-fixture'
    status: 'done'
"""

EXEC_STATUS_DONE = """\
development_status:
  current_iteration: 1
  phase: 'build'
  audit_passed: true
stories:
  e01s01:
    status: 'done'
  e01s02:
    status: 'done'
"""

EXEC_STATUS_BACKLOG = """\
development_status:
  current_iteration: 1
  phase: 'build'
  audit_passed: true
stories:
  e01s01:
    status: 'backlog'
  e01s02:
    status: 'backlog'
"""

RELEASE_PLAN_NO_CAPSULE = """\
release:
  version: '9.9.9'
epics:
  - id: 'e01'
    title: 'Fixture epic with no capsule'
    wsjf: 10
    bcps: 3
    status: 'proposed'
"""

EPIC = """\
id: 'e01'
title: 'Fixture epic'
stories:
  - id: 'e01s01'
    title: 'Tagged behaviour'
    bcp: 2
  - id: 'e01s02'
    title: 'Untagged behaviour'
    bcp: 1
"""


class TraceStoriesCase(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        (self.root / "specs" / "epics" / "e01-fixture").mkdir(parents=True)
        (self.root / "src").mkdir()
        (self.root / "specs" / "release-plan.yaml").write_text(RELEASE_PLAN, encoding="utf-8")
        self.write_capsule()

    def tearDown(self):
        self._tmp.cleanup()

    def write_capsule(self, archived: bool = False):
        live_dir = self.root / "specs" / "epics" / "e01-fixture"
        live = live_dir / "epic.yaml"
        if not archived:
            live.write_text(EPIC, encoding="utf-8")
            return
        target = self.root / "specs" / "epics" / "archive" / "e01-fixture" / "epic.yaml"
        target.parent.mkdir(parents=True, exist_ok=True)
        if live.exists():
            live.unlink()
        live_dir.rmdir()
        target.write_text(EPIC, encoding="utf-8")

    def write_exec_status(self, body: str):
        (self.root / "specs" / "execution-status.yaml").write_text(body, encoding="utf-8")

    def tag(self, story_id: str, path: str = "src/demo.ts"):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        with open(target, "a", encoding="utf-8") as handle:
            handle.write(f"// story: {story_id}\n")

    def run_gate(self, strict: bool = True):
        return subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                str(self.root),
                str(self.root / "matrix.json"),
                str(self.root / "TRACE.md"),
                str(self.root / "wiki"),
                "1" if strict else "0",
                "",
            ],
            capture_output=True,
            text=True,
        )


class StoryStatusSource(TraceStoriesCase):
    """The defect: status was read from `development_status:`."""

    def setUp(self):
        super().setUp()
        self.write_exec_status(EXEC_STATUS_DONE)
        self.tag("e01s01")  # e01s02 stays dark, and it is done

    def test_strict_fails_on_a_done_story_with_no_code_links(self):
        result = self.run_gate(strict=True)

        self.assertEqual(
            result.returncode,
            2,
            f"--strict must fail on the dark done story; stdout={result.stdout!r} stderr={result.stderr!r}",
        )
        self.assertIn("e01s02", result.stderr)

    def test_lifecycle_metadata_does_not_shadow_story_status(self):
        # `development_status:` exists and is populated in every fixture; if it
        # is read as the status source, no story is ever "done" and the gate
        # above passes vacuously.
        result = self.run_gate(strict=True)
        self.assertNotEqual(result.returncode, 0)


class ArchiveFallback(TraceStoriesCase):
    """land-branch.sh archives capsules; release-plan keeps the old path."""

    def setUp(self):
        super().setUp()
        self.write_exec_status(EXEC_STATUS_DONE)
        self.write_capsule(archived=True)
        self.tag("e01s01")
        self.tag("e01s02")

    def test_archived_capsule_still_counts_its_stories(self):
        result = self.run_gate(strict=True)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("**Total stories:** 2", (self.root / "TRACE.md").read_text(encoding="utf-8"))

    def test_missing_capsule_fails_strict_instead_of_passing_vacuously(self):
        # No live capsule and no archive: the epic's stories vanish, which used
        # to leave a one-story matrix that still passed.
        archived = self.root / "specs" / "epics" / "archive" / "e01-fixture" / "epic.yaml"
        archived.unlink()
        (self.root / "specs" / "epics" / "e01-fixture").mkdir(parents=True)

        result = self.run_gate(strict=True)

        self.assertEqual(result.returncode, 2, result.stdout)
        self.assertIn("e01", result.stderr)


class UnimplementedPlan(TraceStoriesCase):
    """Documented contract (BUG-2026-07-06T205700, scripts/test-trace-strict.sh):
    an unimplemented story must not block --strict. Only used to reach the
    anti-vacuity floors, never to hide a done story."""

    def setUp(self):
        super().setUp()
        self.write_exec_status(EXEC_STATUS_BACKLOG)

    def test_strict_passes_when_every_story_is_still_unimplemented(self):
        result = self.run_gate(strict=True)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.root / "matrix.json").is_file())


class DegenerateMatrix(TraceStoriesCase):
    """G-10 (scripts/golden-g10-trace-anti-vacuity.sh): a release plan that
    produces 0 stories must fail --strict, never pass vacuously."""

    def setUp(self):
        super().setUp()
        (self.root / "specs" / "release-plan.yaml").write_text(
            RELEASE_PLAN_NO_CAPSULE, encoding="utf-8"
        )
        (self.root / "specs" / "epics" / "e01-fixture" / "epic.yaml").unlink()
        (self.root / "specs" / "epics" / "e01-fixture").rmdir()
        self.write_exec_status(EXEC_STATUS_DONE)

    def test_strict_fails_on_a_zero_story_matrix(self):
        result = self.run_gate(strict=True)

        self.assertEqual(result.returncode, 2, result.stdout)
        self.assertIn("0 stories", result.stderr)


class FullyCovered(TraceStoriesCase):
    def setUp(self):
        super().setUp()
        self.write_exec_status(EXEC_STATUS_DONE)
        self.tag("e01s01")
        self.tag("e01s02", path="src/other.ts")

    def test_strict_passes_when_every_done_story_is_linked(self):
        result = self.run_gate(strict=True)

        self.assertEqual(result.returncode, 0, result.stderr)
        trace = (self.root / "TRACE.md").read_text(encoding="utf-8")
        self.assertIn("**Total stories:** 2", trace)
        self.assertIn("**Dark stories:** 0", trace)


if __name__ == "__main__":
    unittest.main(verbosity=2)
