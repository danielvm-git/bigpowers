#!/usr/bin/env python3
# story: e58s06
"""tests/test_ab_pi.py — pi adapter: pi-json metrics parser and the config default adapter.

Run: python3 tests/test_ab_pi.py
"""
import json
import sys
import unittest
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_ab_eval import Sandbox, met  # noqa: E402


def assistant_end(inp, out, cache_read, cost, stop="toolUse"):
    usage = {"input": inp, "output": out, "cacheRead": cache_read, "cacheWrite": 0, "cost": {"total": cost}}
    return {"type": "message_end", "message": {"role": "assistant", "stopReason": stop, "usage": usage}}


def stream(*events):
    return "\n".join(json.dumps(e) for e in events)


class TestPiParser(unittest.TestCase):
    def test_sums_assistant_usage(self):
        out = stream({"type": "session", "id": "x"},
                     {"type": "message_end", "message": {"role": "user", "content": "hi"}},
                     assistant_end(1390, 56, 256, 0.000243),
                     assistant_end(55, 3, 1664, 0.000015, stop="stop"),
                     {"type": "agent_settled", "aborted": False})
        m = met.parse_metrics("pi-json", out)
        self.assertEqual((m["input_tokens"], m["output_tokens"], m["turns"]), (1390 + 256 + 55 + 1664, 59, 2))
        self.assertAlmostEqual(m["cost_usd"], 0.000258)
        self.assertFalse(m["agent_reported_error"])

    def test_provider_error_is_agent_error(self):
        out = stream(assistant_end(10, 0, 0, 0.0, stop="error"), {"type": "agent_settled", "aborted": False})
        self.assertTrue(met.parse_metrics("pi-json", out)["agent_reported_error"])

    def test_aborted_run_is_agent_error(self):
        out = stream(assistant_end(10, 1, 0, 0.0, stop="stop"), {"type": "agent_settled", "aborted": True})
        self.assertTrue(met.parse_metrics("pi-json", out)["agent_reported_error"])

    def test_no_events_is_unknown(self):
        self.assertIsNone(met.parse_metrics("pi-json", "boom")["agent_reported_error"])


class TestDefaultAdapter(Sandbox):
    def test_config_default_adapter_is_used(self):
        config = yaml.safe_load(self.config.read_text())
        config["adapters"]["fakepi"] = {"command": "echo 42 > answer.txt", "parser": "none"}
        config["default_adapter"] = "fakepi"
        self.config.write_text(yaml.safe_dump(config))
        _, out = self.run_main("--arms", "vanilla")
        self.assertIn("adapter 'fakepi'", out)
        self.assertTrue(self.records()[0]["pass"])


if __name__ == "__main__":
    unittest.main(verbosity=1)
