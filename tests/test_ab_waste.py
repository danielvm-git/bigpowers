#!/usr/bin/env python3
# story: e58s09
"""tests/test_ab_waste.py — lean waste metrics: relearning, rework, first-time-through, patch metrics.

Run: python3 tests/test_ab_waste.py
"""
import gzip
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_ab_eval import Sandbox, load_module  # noqa: E402

waste = load_module("ab_waste", "ab_waste.py")


class Stream:
    """Builds a pi JSON transcript: assistant turns with one tool call each, plus tool results."""

    def __init__(self):
        self.events, self.t, self.n = [], 0, 0

    def call(self, tool, args, result_text="ok", exit_code=0):
        self.n += 1
        cid = f"c{self.n}"
        self.events.append({"type": "message_end", "message": {
            "role": "assistant", "timestamp": self.t * 1000, "usage": {"output": 5, "cost": {"total": 0.001}},
            "content": [{"type": "toolCall", "name": tool, "arguments": args}]}})
        self.events.append({"type": "tool_execution_start", "toolCallId": cid, "toolName": tool, "args": args})
        result = {"content": [{"type": "text", "text": result_text}], "details": {"exit_code": exit_code}}
        self.events.append({"type": "tool_execution_end", "toolCallId": cid, "toolName": tool,
                            "result": result, "isError": False})
        self.events.append({"type": "message_end", "message": {"role": "toolResult",
                                                               "timestamp": (self.t + 1) * 1000}})
        self.t += 10
        return self

    def text(self):
        return "\n".join(json.dumps(e) for e in self.events)


class TestTranscriptWaste(unittest.TestCase):
    def test_relearning_and_rework_are_counted(self):
        stream = (Stream()
                  .call("read", {"path": "/work/src/a.js"})
                  .call("read", {"path": "/work/src/a.js"})
                  .call("bash", {"command": "ls"})
                  .call("bash", {"command": "ls"})
                  .call("edit", {"path": "/work/src/a.js"})
                  .call("bash", {"command": "npm test 2>&1 | tail"}, "ℹ pass 3\nℹ fail 1\n")
                  .call("edit", {"path": "/work/src/a.js"})
                  .call("bash", {"command": "npm test 2>&1 | tail"}, "ℹ pass 4\nℹ fail 0\n"))
        got = waste.transcript_waste(stream.text())
        self.assertEqual((got["rereads"], got["repeated_commands"], got["test_runs"], got["rework_loops"],
                          got["reedits"], got["ftt"]), (1, 1, 2, 1, 1, False))

    def test_non_zero_exit_is_a_failing_run(self):
        stream = Stream().call("edit", {"path": "/work/src/a.js"}).call(
            "bash", {"command": "node --test test/"}, "boom", exit_code=1)
        self.assertEqual(waste.transcript_waste(stream.text())["rework_loops"], 1)

    def test_clean_run_is_first_time_through(self):
        stream = Stream().call("edit", {"path": "/work/src/a.js"}).call(
            "bash", {"command": "npm test"}, "# pass 5\n# fail 0\n")
        got = waste.transcript_waste(stream.text())
        self.assertEqual((got["rework_loops"], got["ftt"]), (0, True))
        self.assertGreater(got["pce"], 0)

    def test_no_transcript_gives_none(self):
        self.assertIsNone(waste.transcript_waste("not json"))


class TestPatchWaste(Sandbox):
    AGENT = ("echo 42 > answer.txt; printf 'a\\nb\\n' > extra.js; "
             "printf 'one two three\\n' > notes.md; echo x > debug.tmp.js")

    def setUp(self):
        super().setUp()
        solution = self.tasks_dir / "t-01" / "solution"
        solution.mkdir()
        (solution / "answer.txt").write_text("42\n")

    def test_patch_metrics_and_saved_patch(self):
        self.run_main("--adapter-cmd", self.AGENT, "--arms", "vanilla")
        got = self.records()[0]["waste"]
        self.assertEqual(got["solution_lines"], 1)
        self.assertIn("extra.js", got["extra_files"])
        self.assertNotIn("answer.txt", got["extra_files"])
        self.assertEqual(got["leftovers"], ["debug.tmp.js"])
        self.assertEqual(got["doc_lines"], 1)
        self.assertGreater(got["diff_ratio"], 1)
        self.assertGreaterEqual(got["review_load"], got["product_lines"] + 3)
        patch = self.out / "traces" / "t-01-vanilla-1.patch.gz"
        self.assertIn("extra.js", gzip.decompress(patch.read_bytes()).decode())

    def test_non_pi_adapter_has_patch_metrics_only(self):
        self.run_main("--adapter-cmd", self.AGENT, "--arms", "vanilla")
        got = self.records()[0]["waste"]
        self.assertIsNone(got["rework_loops"])
        self.assertIsNotNone(got["review_load"])


if __name__ == "__main__":
    unittest.main(verbosity=1)
