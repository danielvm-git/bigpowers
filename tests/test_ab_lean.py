#!/usr/bin/env python3
# story: e58s10
"""tests/test_ab_lean.py — lean views: per-arm VSM and waste summary, deltas, bars, redundant tests.

Run: python3 tests/test_ab_lean.py
"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_ab_eval import load_module, rep  # noqa: E402
from test_ab_waste import Stream, waste  # noqa: E402

lean = load_module("ab_lean", "ab_lean.py")


def run(arm, lead, build, test, passed=True, cost=0.01, test_runs=3, rework=0):
    stages = {"plan": {"s": lead * 0.1}, "design": {"s": lead * 0.2}, "build": {"s": build}, "test": {"s": test}}
    vsm = {"lead_time_s": lead, "time_to_first_build_s": lead * 0.3, "switches": 4, "stages": stages}
    w = {"test_runs": test_runs, "redundant_test_runs": 1, "rework_loops": rework, "reedits": 0,
         "rereads": 0, "repeated_commands": 0, "review_load": 50, "diff_ratio": 1.2, "ftt": rework == 0,
         "pce": round((build + test) / lead, 3), "leftovers": [], "extra_files": []}
    return {"task": "t", "arm": arm, "pass": passed, "score": None, "tampered": False, "agent_error": False,
            "cost_usd": cost, "input_tokens": None, "output_tokens": None, "turns": 5, "duration_s": lead,
            "diff_lines": 5, "vsm": vsm, "waste": w}


def records():
    return ([run("vanilla", 70, 28, 21) for _ in range(5)]
            + [run("bigpowers", 140, 20, 70, cost=0.02, test_runs=8, rework=1) for _ in range(5)])


class TestLeanSummary(unittest.TestCase):
    def test_per_arm_summary_and_deltas(self):
        summary = lean.lean_summary(records(), ["vanilla", "bigpowers"])
        va, bp = summary["arms"]["vanilla"], summary["arms"]["bigpowers"]
        self.assertEqual(va["lead_time_s"], 70)
        self.assertEqual(round(va["stage_share"]["build"], 2), 0.4)
        self.assertEqual(bp["waste"]["test_runs"], 8)
        self.assertEqual(bp["ftt_rate"], 0.0)
        self.assertEqual(va["cost_per_pass"], 0.01)
        d = summary["deltas"]["bigpowers"]
        self.assertEqual(d["lead_time_s"]["delta"], 70)
        self.assertEqual(d["test_runs"]["delta"], 5)
        self.assertEqual(len(d["build_share"]["ci95"]), 2)

    def test_old_records_give_none(self):
        old = [{k: v for k, v in r.items() if k not in ("vsm", "waste")} for r in records()]
        self.assertIsNone(lean.lean_summary(old, ["vanilla", "bigpowers"]))
        self.assertEqual(lean.lean_lines(None), [])

    def test_report_carries_lean(self):
        result = rep.aggregate(records(), ["vanilla", "bigpowers"], ["t"])
        self.assertIn("bigpowers", result["lean"]["deltas"])


class TestViews(unittest.TestCase):
    def test_bars_scale_with_lead_time(self):
        lines = lean.lean_lines(lean.lean_summary(records(), ["vanilla", "bigpowers"]))
        bars = {line.split()[0]: line for line in lines if line.split() and line.split()[0] in ("vanilla", "bigpowers")}
        va_len = bars["vanilla"].count("|") and len(bars["vanilla"].split("|")[1].rstrip())
        bp_len = len(bars["bigpowers"].split("|")[1].rstrip())
        self.assertAlmostEqual(bp_len / va_len, 2, delta=0.2)
        self.assertIn("T", bars["bigpowers"])
        self.assertTrue(any("rework" in line for line in lines))


class TestRedundantTestRuns(unittest.TestCase):
    def test_repeated_green_run_without_edit_is_redundant(self):
        stream = (Stream()
                  .call("edit", {"path": "/work/src/a.js"})
                  .call("bash", {"command": "npm test"}, "# pass 3\n# fail 0\n")
                  .call("bash", {"command": "npm test 2>&1 | tail -3"}, "# pass 3\n# fail 0\n")
                  .call("edit", {"path": "/work/src/a.js"})
                  .call("bash", {"command": "npm test"}, "# pass 3\n# fail 0\n"))
        self.assertEqual(waste.transcript_waste(stream.text())["redundant_test_runs"], 1)


if __name__ == "__main__":
    unittest.main(verbosity=1)
