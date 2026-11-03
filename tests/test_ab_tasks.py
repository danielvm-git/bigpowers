#!/usr/bin/env python3
# story: e58s01 e58s02 e58s07
"""tests/test_ab_tasks.py — every shipped A/B task is calibrated: its fixture fails, its reference
solution passes, its prompt never names bigpowers, and its grade command uses file globs.

Run: python3 tests/test_ab_tasks.py
Split from test_ab_eval.py (300-line cap).
"""
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_ab_eval import REPO_ROOT  # noqa: E402


@unittest.skipUnless(shutil.which("node"), "node is needed for the starter tasks")
class TestStarterTasks(unittest.TestCase):
    """Each shipped task must fail as given and pass with its reference solution."""

    TASKS = REPO_ROOT / "specs" / "benchmarks" / "ab" / "tasks"

    def grade_copy(self, task_dir: Path, with_solution: bool) -> bool:
        task = yaml.safe_load((task_dir / "task.yaml").read_text())
        work = Path(tempfile.mkdtemp(prefix="ab-starter-"))
        try:
            shutil.copytree(task_dir / "fixture", work, dirs_exist_ok=True)
            if with_solution:
                shutil.copytree(task_dir / "solution", work, dirs_exist_ok=True)
            shutil.copytree(task_dir / "hidden", work, dirs_exist_ok=True)
            res = subprocess.run(["bash", "-c", task["grade"]], cwd=work, capture_output=True)
            return res.returncode == 0
        finally:
            shutil.rmtree(work, ignore_errors=True)

    def test_eight_tasks_ship(self):
        self.assertGreaterEqual(len(list(self.TASKS.glob("*/task.yaml"))), 8)

    def test_fixture_fails_and_solution_passes(self):
        for task_yaml in sorted(self.TASKS.glob("*/task.yaml")):
            with self.subTest(task=task_yaml.parent.name):
                self.assertFalse(self.grade_copy(task_yaml.parent, with_solution=False))
                self.assertTrue(self.grade_copy(task_yaml.parent, with_solution=True))

    def test_prompts_never_name_bigpowers(self):
        for task_yaml in self.TASKS.glob("*/task.yaml"):
            self.assertNotIn("bigpowers", yaml.safe_load(task_yaml.read_text())["prompt"].lower())

    def test_grade_commands_never_pass_a_bare_directory(self):
        """`node --test test/` exits 1 on node 24 (it resolves the directory as a module path), so
        such a task can never pass however good the solution is, while a hidden-only `score`
        command still looks healthy (BUG found in e58s07: ab-11 and ab-13 read pass=0 forever)."""
        for task_yaml in self.TASKS.glob("*/task.yaml"):
            with self.subTest(task=task_yaml.parent.name):
                for token in yaml.safe_load(task_yaml.read_text())["grade"].split():
                    self.assertNotIn(token.rstrip("/"), ("test", "test-hidden"),
                                     f"{task_yaml.parent.name} grades a directory, not a glob")


if __name__ == "__main__":
    unittest.main(verbosity=1)
