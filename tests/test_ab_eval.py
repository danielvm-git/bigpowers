#!/usr/bin/env python3
# story: e58s01
"""tests/test_ab_eval.py — A/B eval runner (vanilla vs bigpowers) with a fake adapter.

Run: python3 tests/test_ab_eval.py
No agent is called: every adapter here is a small shell command.
"""
import importlib.util
import io
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]
LIB = REPO_ROOT / "scripts" / "lib"


def load_module(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, LIB / filename)
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


ab = load_module("ab_eval", "ab-eval.py")
rep = load_module("ab_report", "ab_report.py")
met = load_module("ab_metrics", "ab_metrics.py")
bench = load_module("run_benchmark", "run-benchmark.py")

SOLVE_IF_SKILLS = 'if [ -d .claude/skills ]; then echo 42 > answer.txt; fi'
CLAUDE_JSON = json.dumps({
    "type": "result", "subtype": "success", "is_error": False, "num_turns": 7,
    "total_cost_usd": 0.1234, "usage": {"input_tokens": 1500, "output_tokens": 300},
    "modelUsage": {"claude-opus-5-5": {"costUSD": 0.1}, "claude-haiku-5-5": {"costUSD": 0.0234}},
})


class Sandbox(unittest.TestCase):
    """Builds a throwaway config + one task, so tests never touch specs/benchmarks/ab/."""

    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="ab-test-"))
        self.tasks_dir = self.tmp / "tasks"
        task = self.tasks_dir / "t-01"
        (task / "fixture" / "test").mkdir(parents=True)
        (task / "fixture" / "test" / "a.test").write_text("keep me\n")
        (task / "hidden").mkdir()
        (task / "hidden" / "secret.check").write_text('test "$(cat answer.txt 2>/dev/null)" = 42\n')
        (task / "task.yaml").write_text(yaml.safe_dump({
            "id": "t-01", "title": "answer", "kind": "feature",
            "prompt": "Write 42 to answer.txt",
            "protected": ["test/a.test"],
            "grade": "sh secret.check",
            "timeout_s": 30,
        }))
        self.config = self.tmp / "config.yaml"
        self.config.write_text(yaml.safe_dump({
            "k": 1,
            "arms": {"vanilla": {"setup": "true"}, "bigpowers": {"setup": "mkdir -p .claude/skills"}},
            "adapters": {"claude": {"command": "false", "parser": "claude-json"}},
        }))
        self.out = self.tmp / "out"

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def run_main(self, *extra):
        argv = ["--config", str(self.config), "--tasks-dir", str(self.tasks_dir),
                "--out", str(self.out), *extra]
        buf = io.StringIO()
        with redirect_stdout(buf):
            code = ab.main(argv)
        return code, buf.getvalue()

    def records(self):
        lines = next(self.out.glob("ab-runs-*.jsonl")).read_text().splitlines()
        return [json.loads(line) for line in lines]


class TestFairComparison(Sandbox):
    def test_skill_dependent_agent_shows_full_delta(self):
        code, _ = self.run_main("--adapter-cmd", SOLVE_IF_SKILLS, "--k", "2")
        self.assertEqual(code, 0)
        report = yaml.safe_load(next(self.out.glob("AB-*.yaml")).read_text())
        self.assertEqual(report["arms_summary"]["bigpowers"]["pass_rate"], 1.0)
        self.assertEqual(report["arms_summary"]["vanilla"]["pass_rate"], 0.0)
        self.assertEqual(report["delta"]["pass_rate"], 1.0)
        self.assertEqual(report["per_task"]["t-01"]["bigpowers"], 1.0)

    def test_hidden_tests_are_not_visible_to_agent(self):
        peek = "find . -name 'secret*' | grep -q . && exit 1; echo 42 > answer.txt"
        self.run_main("--adapter-cmd", peek, "--arms", "vanilla")
        self.assertTrue(all(r["pass"] for r in self.records()))

    def test_workdir_lives_outside_repo(self):
        where = f"pwd > {self.tmp}/where.txt"
        self.run_main("--adapter-cmd", where, "--arms", "vanilla")
        workdir = Path((self.tmp / "where.txt").read_text().strip()).resolve()
        self.assertNotIn(str(REPO_ROOT.resolve()), str(workdir))


class TestRunRecord(Sandbox):
    def test_deleting_protected_test_is_tampering(self):
        self.run_main("--adapter-cmd", "rm test/a.test; echo 42 > answer.txt", "--arms", "vanilla")
        rec = self.records()[0]
        self.assertTrue(rec["tampered"])
        self.assertTrue(rec["pass"])

    def test_untouched_protected_test_is_not_tampering(self):
        self.run_main("--adapter-cmd", "echo 42 > answer.txt", "--arms", "vanilla")
        self.assertFalse(self.records()[0]["tampered"])

    def test_appending_tests_is_not_tampering(self):  # TDD arms add tests to visible files
        self.run_main("--adapter-cmd", "echo more >> test/a.test; echo 42 > answer.txt", "--arms", "vanilla")
        rec = self.records()[0]
        self.assertFalse(rec["tampered"])
        self.assertEqual(rec["protected_lines_added"], 1)

    def test_editing_a_protected_line_is_tampering(self):
        self.run_main("--adapter-cmd", "echo weak > test/a.test; echo 42 > answer.txt", "--arms", "vanilla")
        self.assertTrue(self.records()[0]["tampered"])

    def test_diff_lines_count_agent_changes_only(self):
        self.run_main("--adapter-cmd", "printf '42\\nx\\n' > answer.txt", "--arms", "bigpowers")
        self.assertEqual(self.records()[0]["diff_lines"], 2)

    def test_agent_failure_is_recorded_not_fatal(self):
        code, _ = self.run_main("--adapter-cmd", "exit 1", "--arms", "vanilla")
        self.assertEqual(code, 0)
        rec = self.records()[0]
        self.assertTrue(rec["agent_error"])
        self.assertFalse(rec["pass"])

    def test_prompt_reaches_adapter(self):
        self.run_main("--adapter-cmd", 'printf "%s" "$AB_PROMPT" > got.txt; cp got.txt ' + str(self.tmp),
                      "--arms", "vanilla")
        self.assertEqual((self.tmp / "got.txt").read_text(), "Write 42 to answer.txt")


class TestMetrics(unittest.TestCase):
    def test_claude_json_fields_are_parsed(self):
        m = met.parse_metrics("claude-json", "noise line\n" + CLAUDE_JSON + "\n")
        self.assertEqual(m["cost_usd"], 0.1234)
        self.assertEqual(m["input_tokens"], 1500)
        self.assertEqual(m["output_tokens"], 300)
        self.assertEqual(m["turns"], 7)
        self.assertEqual(m["models"], ["claude-haiku-5-5", "claude-opus-5-5"])
        self.assertFalse(m["agent_reported_error"])

    def test_unparseable_output_gives_nulls(self):
        m = met.parse_metrics("claude-json", "not json")
        self.assertIsNone(m["cost_usd"])

    def test_bootstrap_is_deterministic_and_brackets_estimate(self):
        a = [True, True, False, True, True, False]
        b = [False, True, False, False, True, False]
        ci1 = rep.bootstrap_delta_ci(a, b)
        ci2 = rep.bootstrap_delta_ci(a, b)
        self.assertEqual(ci1, ci2)
        self.assertLessEqual(ci1[0], 2 / 6)
        self.assertGreaterEqual(ci1[1], 2 / 6)


OPENCODE_JSONL = "\n".join(json.dumps(e) for e in [
    {"type": "step_start", "part": {"type": "step-start"}},
    {"type": "step_finish", "part": {"type": "step-finish", "cost": 0.01,
                                     "tokens": {"input": 100, "output": 20, "reasoning": 5,
                                                "cache": {"read": 300, "write": 50}}}},
    {"type": "text", "part": {"type": "text", "text": "done"}},
    {"type": "step_finish", "part": {"type": "step-finish", "cost": 0.02,
                                     "tokens": {"input": 10, "output": 2, "reasoning": 0,
                                                "cache": {"read": 400, "write": 0}}}},
])


class TestOpencodeParser(unittest.TestCase):
    def test_opencode_jsonl_sums_steps(self):
        m = met.parse_metrics("opencode-jsonl", "log noise\n" + OPENCODE_JSONL + "\n")
        self.assertAlmostEqual(m["cost_usd"], 0.03)
        self.assertEqual(m["input_tokens"], 100 + 300 + 50 + 10 + 400)
        self.assertEqual(m["output_tokens"], 20 + 5 + 2)
        self.assertEqual(m["turns"], 2)
        self.assertFalse(m["agent_reported_error"])

    def test_opencode_error_event_is_agent_error(self):
        out = OPENCODE_JSONL + "\n" + json.dumps({"type": "error", "error": {"name": "APIError"}})
        self.assertTrue(met.parse_metrics("opencode-jsonl", out)["agent_reported_error"])

    def test_opencode_without_steps_gives_nulls(self):
        self.assertIsNone(met.parse_metrics("opencode-jsonl", "")["cost_usd"])


class TestRunEnvironment(Sandbox):
    def test_each_run_gets_fresh_home_removed_afterwards(self):
        cmd = (f'ls -A "$AB_HOME" | wc -l | tr -d " " > {self.tmp}/n.txt; '
               f'echo "$AB_HOME" > {self.tmp}/home.txt; echo 42 > answer.txt')
        self.run_main("--adapter-cmd", cmd, "--arms", "vanilla")
        self.assertEqual((self.tmp / "n.txt").read_text().strip(), "0")
        home = Path((self.tmp / "home.txt").read_text().strip())
        self.assertTrue(str(home))
        self.assertFalse(home.exists())

    def test_adapter_stdin_is_closed(self):
        self.run_main("--adapter-cmd", "cat > /dev/null; echo 42 > answer.txt", "--arms", "vanilla")
        self.assertTrue(self.records()[0]["pass"])

    def test_adapter_default_model_is_used_and_recorded(self):
        cfg = yaml.safe_load(self.config.read_text())
        cfg["adapters"]["fake"] = {
            "command": f'printf "%s" "$AB_MODEL" > {self.tmp}/model.txt; echo 42 > answer.txt',
            "parser": "none", "default_model": "prov/model-x"}
        self.config.write_text(yaml.safe_dump(cfg))
        self.run_main("--adapter", "fake", "--arms", "vanilla")
        self.assertEqual((self.tmp / "model.txt").read_text(), "prov/model-x")
        report = yaml.safe_load(next(self.out.glob("AB-*.yaml")).read_text())
        self.assertEqual(report["model"], "prov/model-x")


class TestCli(Sandbox):
    def test_unknown_arm_exits_2(self):
        code, out = self.run_main("--arms", "nope")
        self.assertEqual(code, 2)
        self.assertIn("vanilla", out)

    def test_unknown_task_exits_2(self):
        code, _ = self.run_main("--tasks", "missing")
        self.assertEqual(code, 2)

    def test_dry_run_spends_nothing(self):
        marker = self.tmp / "ran.txt"
        code, out = self.run_main("--adapter-cmd", f"touch {marker}", "--dry-run")
        self.assertEqual(code, 0)
        self.assertFalse(marker.exists())
        self.assertIn("t-01", out)
        self.assertFalse(self.out.exists())

    def test_single_arm_has_no_delta(self):
        self.run_main("--adapter-cmd", "true", "--arms", "vanilla")
        report = yaml.safe_load(next(self.out.glob("AB-*.yaml")).read_text())
        self.assertIsNone(report["delta"])


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


class TestRunBenchmarkHonesty(unittest.TestCase):
    def test_without_skill_arm_is_unmeasured_not_zero(self):
        sc = {"id": "s1", "grader": {"type": "code", "command": "true"}}
        _, status = bench.scenario_pass_rate(sc, runs=1, with_skill=False)
        self.assertEqual(status, "unmeasured")
        report = bench.build_split_report([sc], runs=1)
        self.assertIsNone(report["without_skill"])
        self.assertIsNone(report["delta"])

    def test_summary_says_unmeasured(self):
        self.assertIn("UNMEASURED", bench.delta_summary(None))


if __name__ == "__main__":
    unittest.main(verbosity=2)
