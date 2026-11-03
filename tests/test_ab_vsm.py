#!/usr/bin/env python3
# story: e58s08
"""tests/test_ab_vsm.py — value stream map per run: stage rules, per-turn time, run records.

Run: python3 tests/test_ab_vsm.py
"""
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_ab_eval import Sandbox, load_module  # noqa: E402

vsm = load_module("ab_vsm", "ab_vsm.py")
STAGES = {"plan", "design", "build", "test", "deploy", "maintain", "wrap-up"}


def assistant(ts_s, cost=0.001, out=10, calls=()):
    content = [{"type": "toolCall", "name": tool, "arguments": args} for tool, args in calls]
    usage = {"input": 100, "output": out, "cacheRead": 0, "cacheWrite": 0, "cost": {"total": cost}}
    return {"type": "message_end", "message": {"role": "assistant", "timestamp": int(ts_s * 1000),
                                               "content": content, "usage": usage}}


def tool_result(ts_s):
    return {"type": "message_end", "message": {"role": "toolResult", "timestamp": int(ts_s * 1000)}}


def transcript():
    events = [
        {"type": "session", "id": "s"},
        {"type": "message_end", "message": {"role": "user", "timestamp": 0}},
        assistant(0, calls=[("read", {"path": "/work/ISSUE.md"})]), tool_result(9),
        assistant(10, calls=[("bash", {"command": "cat src/reports.js"})]), tool_result(24),
        assistant(25, calls=[("edit", {"path": "/work/src/reports.js"})]), tool_result(39),
        assistant(40, calls=[("bash", {"command": "npm test 2>&1 | tail"})]), tool_result(49),
        assistant(50, calls=[("bash", {"command": "git commit -am fix"})]), tool_result(54),
        assistant(55, out=40),
        {"type": "agent_settled", "aborted": False},
    ]
    return "\n".join(json.dumps(e) for e in events)


class TestRules(unittest.TestCase):
    def setUp(self):
        self.rules = vsm.load_rules()

    def test_rules_file_uses_known_stages(self):
        self.assertTrue({r["stage"] for r in self.rules["rules"]} <= STAGES)
        self.assertTrue(set(self.rules["turn_priority"]) <= STAGES)

    def test_calls_are_classified(self):
        cases = [
            ("read", {"path": "/work/ISSUE.md"}, "plan"),
            ("bash", {"command": "sed -n 1,80p .agents/skills/fix-bug/SKILL.md"}, "plan"),
            ("read", {"path": "/work/src/reports.js"}, "design"),
            ("edit", {"path": "/work/src/reports.js"}, "build"),
            ("edit", {"path": "/work/test/ledger.test.js"}, "test"),
            ("bash", {"command": "npm test 2>&1 | tail -20"}, "test"),
            ("bash", {"command": "node --test test/"}, "test"),
            ("bash", {"command": "git checkout -b fix/rounding"}, "deploy"),
            ("bash", {"command": "git commit -am 'fix'"}, "deploy"),
            ("write", {"path": "/work/specs/bugs/BUG-001.md"}, "maintain"),
            ("edit", {"path": "/work/docs/LEDGER.md"}, "maintain"),
            ("write", {"path": "/work/specs/plan.md"}, "plan"),
        ]
        for tool, args, expected in cases:
            with self.subTest(tool=tool, args=args):
                self.assertEqual(vsm.classify_call(tool, args, self.rules), expected)


class TestStageTime(unittest.TestCase):
    def test_turn_time_goes_to_the_stage_of_its_action(self):
        block = vsm.vsm_from("pi-json", transcript())
        seconds = {stage: round(v["s"], 1) for stage, v in block["stages"].items()}
        self.assertEqual(seconds, {"plan": 10.0, "design": 15.0, "build": 15.0, "test": 10.0,
                                   "deploy": 5.0, "wrap-up": 0.0})
        self.assertEqual(block["lead_time_s"], 55.0)
        self.assertEqual(block["time_to_first_build_s"], 25.0)
        self.assertEqual(block["switches"], 5)
        self.assertEqual(block["sequence"], ["plan", "design", "build", "test", "deploy", "wrap-up"])
        self.assertEqual(block["stages"]["wrap-up"]["output_tokens"], 40)
        self.assertAlmostEqual(sum(v["cost_usd"] for v in block["stages"].values()), 0.006)

    def test_build_wins_a_turn_with_several_calls(self):
        events = [assistant(0, calls=[("read", {"path": "/work/ISSUE.md"}), ("edit", {"path": "/work/src/a.js"})]),
                  tool_result(5)]
        block = vsm.vsm_from("pi-json", "\n".join(json.dumps(e) for e in events))
        self.assertEqual(block["sequence"], ["build"])

    def test_unsupported_or_empty_is_none(self):
        self.assertIsNone(vsm.vsm_from("none", transcript()))
        self.assertIsNone(vsm.vsm_from("pi-json", "not json"))


class TestRunRecord(Sandbox):
    def test_record_carries_vsm(self):
        script = self.tmp / "transcript.jsonl"
        script.write_text(transcript() + "\n")
        self.run_main("--adapter-cmd", f"cat {script}; echo 42 > answer.txt", "--parser", "pi-json",
                      "--arms", "vanilla")
        rec = self.records()[0]
        self.assertEqual(rec["vsm"]["stages"]["build"]["turns"], 1)
        self.assertEqual(rec["vsm"]["lead_time_s"], 55.0)


if __name__ == "__main__":
    unittest.main(verbosity=1)
