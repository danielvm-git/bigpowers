#!/usr/bin/env python3
# story: e58s03
"""tests/test_ab_score.py — partial-credit scoring and the hard tasks (ab-11, ab-13).

Run: python3 tests/test_ab_score.py
Split from test_ab_eval.py (300-line cap); reuses its Sandbox and module loaders.
"""
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_ab_eval import REPO_ROOT, Sandbox, met, rep  # noqa: E402

TASKS = REPO_ROOT / "specs" / "benchmarks" / "ab" / "tasks"
HARD_TASKS = [
    "ab-09-inventory-reservations",
    "ab-11-ledger-rounding",
    "ab-13-orders-split",
    "ab-17-payment-alias",
    "ab-19-catalog-segregation",
    "ab-20-brand-discount",
]


class TestTapScore(unittest.TestCase):
    def test_share_of_passing_tests(self):
        self.assertEqual(met.tap_score("# tests 4\n# pass 3\n# fail 1\n"), 0.75)

    def test_several_summaries_are_summed(self):
        self.assertEqual(met.tap_score("# pass 2\n# fail 0\nnoise\n# pass 1\n# fail 1\n"), 0.75)

    def test_no_summary_is_none(self):
        self.assertIsNone(met.tap_score("SyntaxError: boom\n"))


class TestScoreInRuns(Sandbox):
    def set_score(self, command):
        task_yaml = self.tasks_dir / "t-01" / "task.yaml"
        task = yaml.safe_load(task_yaml.read_text())
        task["score"] = command
        task_yaml.write_text(yaml.safe_dump(task))

    def test_score_command_sets_score(self):
        self.set_score("printf '# pass 3\\n# fail 1\\n'; exit 1")
        self.run_main("--adapter-cmd", "echo 42 > answer.txt", "--arms", "vanilla")
        self.assertEqual(self.records()[0]["score"], 0.75)

    def test_no_score_key_means_null(self):
        self.run_main("--adapter-cmd", "echo 42 > answer.txt")
        self.assertIsNone(self.records()[0]["score"])
        report = yaml.safe_load(next(self.out.glob("AB-*.yaml")).read_text())
        self.assertIsNone(report["delta"].get("score"))


class TestScoreInReport(unittest.TestCase):
    def rec(self, arm, task, score):
        return {"arm": arm, "task": task, "pass": score == 1.0, "tampered": False, "agent_error": False,
                "cost_usd": None, "input_tokens": None, "output_tokens": None, "turns": None,
                "duration_s": 1.0, "diff_lines": 1, "score": score}

    def test_mean_score_and_delta(self):
        records = [self.rec("vanilla", "t", 0.5), self.rec("vanilla", "t", 0.7),
                   self.rec("bigpowers", "t", 0.9), self.rec("bigpowers", "t", 1.0)]
        result = rep.aggregate(records, ["vanilla", "bigpowers"], ["t"])
        self.assertEqual(result["arms_summary"]["vanilla"]["mean_score"], 0.6)
        self.assertEqual(result["per_task_score"]["t"]["bigpowers"], 0.95)
        self.assertEqual(result["delta"]["score"], 0.35)
        lo, hi = result["delta"]["score_ci95"]
        self.assertLessEqual(lo, 0.35)
        self.assertGreaterEqual(hi, 0.35)


@unittest.skipUnless(shutil.which("node"), "node is needed for the hard tasks")
class TestHardTasks(unittest.TestCase):
    """Each hard task must fail as given, pass with its solution, and give partial credit."""

    def grade(self, name: str, with_solution: bool) -> tuple[bool, float | None]:
        task_dir = TASKS / name
        task = yaml.safe_load((task_dir / "task.yaml").read_text())
        work = Path(tempfile.mkdtemp(prefix="ab-hard-"))
        try:
            shutil.copytree(task_dir / "fixture", work, dirs_exist_ok=True)
            if with_solution:
                shutil.copytree(task_dir / "solution", work, dirs_exist_ok=True)
            shutil.copytree(task_dir / "hidden", work, dirs_exist_ok=True)
            run = lambda cmd: subprocess.run(["bash", "-c", cmd], cwd=work, capture_output=True, text=True)
            passed = run(task["grade"]).returncode == 0
            return passed, met.tap_score(run(task["score"]).stdout)
        finally:
            shutil.rmtree(work, ignore_errors=True)

    def test_fixture_fails_with_partial_score(self):
        for name in HARD_TASKS:
            with self.subTest(task=name):
                passed, score = self.grade(name, with_solution=False)
                self.assertFalse(passed)
                assert score is not None
                self.assertLess(score, 1.0)

    def test_solution_passes_with_full_score(self):
        for name in HARD_TASKS:
            with self.subTest(task=name):
                self.assertEqual(self.grade(name, with_solution=True), (True, 1.0))

    def test_score_runs_hidden_tests_only(self):
        for name in HARD_TASKS:
            with self.subTest(task=name):
                score_cmd = yaml.safe_load((TASKS / name / "task.yaml").read_text())["score"]
                self.assertIn("test-hidden", score_cmd)
                self.assertNotRegex(score_cmd, r"(^|\s)test/")


if __name__ == "__main__":
    unittest.main(verbosity=1)
