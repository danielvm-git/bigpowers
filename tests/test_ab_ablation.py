#!/usr/bin/env python3
# story: e58s04
"""tests/test_ab_ablation.py — ablation arms: skill subsets, seed choice, per-arm deltas.

Run: python3 tests/test_ab_ablation.py
"""
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_ab_eval import REPO_ROOT, rep  # noqa: E402

ARM_SCRIPT = REPO_ROOT / "scripts" / "lib" / "ab-arm-bigpowers.sh"


class TestArmSetup(unittest.TestCase):
    def setup_arm(self, **env):
        work = Path(tempfile.mkdtemp(prefix="ab-arm-"))
        self.addCleanup(shutil.rmtree, work, ignore_errors=True)
        full_env = {**os.environ, "AB_BP_ROOT": str(REPO_ROOT), **env}
        subprocess.run(["bash", str(ARM_SCRIPT)], cwd=work, env=full_env, check=True, capture_output=True)
        return work

    def skills(self, work, folder):
        path = work / folder / "skills"
        return sorted(p.name for p in path.iterdir()) if path.is_dir() else []

    def test_default_installs_every_skill_and_the_seed(self):
        work = self.setup_arm()
        self.assertEqual(len(self.skills(work, ".agents")), len(list((REPO_ROOT / "skills").glob("*/"))))
        self.assertTrue((work / "AGENTS.md").is_file())
        self.assertTrue((work / "scripts").is_dir())

    def test_skill_subset(self):
        work = self.setup_arm(AB_BP_SKILLS="develop-tdd,verify-work")
        self.assertEqual(self.skills(work, ".agents"), ["develop-tdd", "verify-work"])
        self.assertEqual(self.skills(work, ".claude"), ["develop-tdd", "verify-work"])
        self.assertTrue((work / "scripts").is_dir())

    def test_unknown_skill_fails_setup(self):
        with self.assertRaises(subprocess.CalledProcessError):
            self.setup_arm(AB_BP_SKILLS="no-such-skill")

    def test_seed_only(self):
        work = self.setup_arm(AB_BP_SKILLS="none")
        self.assertTrue((work / "AGENTS.md").is_file())
        self.assertEqual(self.skills(work, ".agents"), [])
        self.assertFalse((work / "scripts").exists())

    def test_skills_without_seed(self):
        work = self.setup_arm(AB_BP_SEED="none")
        self.assertFalse((work / "AGENTS.md").exists())
        self.assertFalse((work / "CLAUDE.md").exists())
        self.assertGreater(len(self.skills(work, ".agents")), 0)

    def test_other_seed_file(self):
        work = self.setup_arm(AB_BP_SKILLS="none", AB_BP_SEED="specs/benchmarks/ab/arms/tdd-line/AGENTS.md")
        self.assertNotIn("bigpowers", (work / "AGENTS.md").read_text().lower())


class TestDeltasVsVanilla(unittest.TestCase):
    def rec(self, arm, passed, score=None):
        return {"arm": arm, "task": "t", "pass": passed, "score": score, "tampered": False, "agent_error": False,
                "cost_usd": 0.01, "input_tokens": None, "output_tokens": None, "turns": None,
                "duration_s": 1.0, "diff_lines": 1}

    def test_every_arm_gets_a_delta(self):
        records = [self.rec("vanilla", False, 0.5), self.rec("vanilla", True, 1.0),
                   self.rec("bigpowers", True, 1.0), self.rec("bigpowers", True, 1.0),
                   self.rec("bp-seed", False, 0.5), self.rec("bp-seed", False, 0.5)]
        result = rep.aggregate(records, ["vanilla", "bigpowers", "bp-seed"], ["t"])
        deltas = result["deltas_vs_vanilla"]
        self.assertEqual(sorted(deltas), ["bigpowers", "bp-seed"])
        self.assertEqual(deltas["bigpowers"]["pass_rate"], 0.5)
        self.assertEqual(deltas["bp-seed"]["pass_rate"], -0.5)
        self.assertEqual(deltas["bp-seed"]["score"], -0.25)
        self.assertEqual(len(deltas["bp-seed"]["ci95"]), 2)
        self.assertEqual(result["delta"], deltas["bigpowers"])

    def test_no_vanilla_means_no_deltas(self):
        result = rep.aggregate([self.rec("bigpowers", True)], ["bigpowers"], ["t"])
        self.assertEqual(result["deltas_vs_vanilla"], {})


if __name__ == "__main__":
    unittest.main(verbosity=1)
