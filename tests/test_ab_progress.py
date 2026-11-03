#!/usr/bin/env python3
# story: e58s05
"""tests/test_ab_progress.py — live records, interleaved runs, saved transcripts, ab_progress.

Run: python3 tests/test_ab_progress.py
"""
import gzip
import io
import json
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_ab_eval import Sandbox, load_module  # noqa: E402

prog = load_module("ab_progress", "ab_progress.py")


class TestLiveRun(Sandbox):
    def live(self):
        return [json.loads(line) for line in (self.out / "ab-live.jsonl").read_text().splitlines()]

    def test_records_stream_with_sha_and_model(self):
        self.run_main("--adapter-cmd", "echo 42 > answer.txt", "--k", "2", "--model", "m-1")
        live = self.live()
        self.assertEqual(len(live), 4)
        self.assertTrue(all(r["bigpowers_sha"] and r["model"] == "m-1" for r in live))

    def test_runs_are_interleaved(self):
        self.run_main("--adapter-cmd", "echo 42 > answer.txt", "--k", "2")
        order = [(r["run"], r["arm"]) for r in self.live()]
        self.assertEqual(order, [(1, "vanilla"), (1, "bigpowers"), (2, "vanilla"), (2, "bigpowers")])

    def test_transcripts_are_saved(self):
        self.run_main("--adapter-cmd", "echo transcript-line; echo 42 > answer.txt", "--arms", "vanilla")
        traces = sorted((self.out / "traces").glob("*.jsonl.gz"))
        self.assertEqual([t.name for t in traces], ["t-01-vanilla-1.jsonl.gz"])
        self.assertIn("transcript-line", gzip.decompress(traces[0].read_bytes()).decode())


class TestProgress(unittest.TestCase):
    def shard(self, tmp: Path, name: str, records: list[dict]) -> Path:
        folder = tmp / name
        folder.mkdir()
        (folder / "ab-live.jsonl").write_text("".join(json.dumps(r) + "\n" for r in records))
        return folder

    def rec(self, arm, run, passed, score):
        return {"task": "ab-11", "arm": arm, "run": run, "pass": passed, "score": score, "tampered": False,
                "agent_error": False, "cost_usd": 0.01, "input_tokens": None, "output_tokens": None,
                "turns": 5, "duration_s": 1.0, "diff_lines": 3, "bigpowers_sha": "abc", "model": "m"}

    def test_reads_shards_and_prints_evolution(self):
        import tempfile
        tmp = Path(tempfile.mkdtemp(prefix="ab-prog-"))
        a = self.shard(tmp, "s1", [self.rec("vanilla", i, i % 2 == 0, 0.5) for i in range(1, 11)]
                       + [self.rec("bigpowers", i, True, 1.0) for i in range(1, 11)])
        b = self.shard(tmp, "s2", [self.rec("vanilla", i, False, 0.4) for i in range(1, 6)]
                       + [self.rec("bigpowers", i, True, 1.0) for i in range(1, 6)])
        buf = io.StringIO()
        with redirect_stdout(buf):
            code = prog.main([str(a), str(b)])
        text = buf.getvalue()
        self.assertEqual(code, 0)
        self.assertIn("30 runs", text)
        self.assertRegex(text, r"ab-11\s+vanilla\s+15")
        self.assertRegex(text, r"ab-11\s+bigpowers\s+15")
        self.assertIn("bigpowers - vanilla", text)
        self.assertIn("evolution", text)

    def test_no_live_file_exits_2(self):
        import tempfile
        buf = io.StringIO()
        with redirect_stdout(buf):
            self.assertEqual(prog.main([tempfile.mkdtemp()]), 2)


if __name__ == "__main__":
    unittest.main(verbosity=1)
