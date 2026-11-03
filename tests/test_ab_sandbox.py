#!/usr/bin/env python3
# story: e58s07
"""tests/test_ab_sandbox.py — Docker sandbox: grade_wrapper, AB_TIMEOUT, container isolation.

Run: python3 tests/test_ab_sandbox.py
The isolation tests need Docker and `bash scripts/ab-sandbox.sh up`; they skip otherwise.
"""
import shutil
import subprocess
import sys
import unittest
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_ab_eval import REPO_ROOT, Sandbox  # noqa: E402

AGENT_IMAGE = "bp-ab-agent:pi-1.5.0"


def sandbox_up() -> bool:
    if not shutil.which("docker"):
        return False
    res = subprocess.run(["bash", str(REPO_ROOT / "scripts" / "ab-sandbox.sh"), "status"], capture_output=True)
    return res.returncode == 0


class TestGradeWrapper(Sandbox):
    def add_adapter(self, **extra):
        config = yaml.safe_load(self.config.read_text())
        config["adapters"]["boxed"] = {"command": "echo $AB_TIMEOUT > timeout.txt; cp timeout.txt "
                                       + str(self.tmp) + "/; echo 42 > answer.txt", "parser": "none", **extra}
        self.config.write_text(yaml.safe_dump(config))

    def test_grade_and_score_go_through_the_wrapper(self):
        log = self.tmp / "wrapped.log"
        self.add_adapter(grade_wrapper=f'echo "$AB_CMD" >> {log}; bash -c "$AB_CMD"')
        task_yaml = self.tasks_dir / "t-01" / "task.yaml"
        task = yaml.safe_load(task_yaml.read_text())
        task["score"] = "printf '# pass 1\\n# fail 0\\n'"
        task_yaml.write_text(yaml.safe_dump(task))
        self.run_main("--adapter", "boxed", "--arms", "vanilla")
        rec = self.records()[0]
        self.assertTrue(rec["pass"])
        self.assertEqual(rec["score"], 1.0)
        self.assertEqual(len(log.read_text().splitlines()), 2)

    def test_timeout_is_exported_with_margin(self):
        self.add_adapter()
        self.run_main("--adapter", "boxed", "--arms", "vanilla")
        self.assertEqual((self.tmp / "timeout.txt").read_text().strip(), "10")


@unittest.skipUnless(sandbox_up(), "Docker sandbox not up (bash scripts/ab-sandbox.sh up)")
class TestIsolation(unittest.TestCase):
    def agent(self, script: str, network: str = "bp-ab-internal") -> subprocess.CompletedProcess:
        return subprocess.run(
            ["docker", "run", "--rm", "--network", network,
             "-e", "HTTPS_PROXY=http://bp-ab-proxy:8888", "-e", "HTTP_PROXY=http://bp-ab-proxy:8888",
             AGENT_IMAGE, "bash", "-c", script], capture_output=True, text=True, timeout=120)

    def test_host_paths_are_invisible(self):
        res = self.agent(f'test ! -e /Users && test ! -e "{REPO_ROOT}" && echo hidden')
        self.assertEqual(res.stdout.strip(), "hidden", res.stderr)

    def test_runs_as_non_root(self):
        self.assertNotEqual(self.agent("id -u").stdout.strip(), "0")

    def test_only_the_model_provider_is_reachable(self):
        probe = "node -e \"fetch(process.argv[1]).then(r=>console.log('ok',r.status)).catch(e=>console.log('blocked'))\""
        self.assertIn("blocked", self.agent(f"{probe} https://example.com").stdout)
        self.assertIn("ok", self.agent(f"{probe} https://opencode.ai").stdout)

    def test_grading_container_has_no_network(self):
        res = self.agent("node -e \"fetch('https://opencode.ai').then(()=>console.log('open'))"
                         ".catch(()=>console.log('none'))\"", network="none")
        self.assertIn("none", res.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=1)
