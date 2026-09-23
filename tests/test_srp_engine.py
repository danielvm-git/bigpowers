#!/usr/bin/env python3
"""tests/test_srp_engine.py — unit tests for rewrite_links_for_pi and link_utils.

Run: python3 -m pytest tests/test_srp_engine.py -v
  or: python3 tests/test_srp_engine.py
"""
import os
import sys
import tempfile
import unittest
from unittest import mock

# Make scripts/lib importable without installation.
_REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_LIB = os.path.join(_REPO_ROOT, "scripts", "lib")
sys.path.insert(0, _LIB)
sys.path.insert(0, os.path.join(_REPO_ROOT, "scripts"))

# srp-engine.py has a hyphen so we load it via importlib.
import importlib.util as _ilu
_spec = _ilu.spec_from_file_location("srp_engine", os.path.join(_LIB, "srp-engine.py"))
_srp = _ilu.module_from_spec(_spec)
sys.modules["srp_engine"] = _srp
_spec.loader.exec_module(_srp)

from srp_engine import rewrite_links_for_pi  # type: ignore[import]
from link_utils import strip_code_spans, LINK_RE, MACHINE_PATH_RE


class TestStripCodeSpans(unittest.TestCase):
    def test_fenced_block_blanked(self):
        md = "Before.\n```\n[fake](fake.md)\n```\nAfter."
        shadow = strip_code_spans(md)
        self.assertNotIn("[fake](fake.md)", shadow)
        self.assertEqual(len(shadow), len(md))  # positions preserved

    def test_inline_code_blanked(self):
        md = "Use `[x](y.md)` as an example."
        shadow = strip_code_spans(md)
        self.assertNotIn("[x](y.md)", shadow)
        self.assertEqual(len(shadow), len(md))

    def test_real_link_survives(self):
        md = "See [docs](guide.md) for details."
        shadow = strip_code_spans(md)
        self.assertIn("[docs](guide.md)", shadow)


class TestLinkRE(unittest.TestCase):
    def test_plain_link(self):
        m = LINK_RE.search("[text](target.md)")
        self.assertIsNotNone(m)
        self.assertEqual(m.group(2), "target.md")

    def test_link_with_title(self):
        m = LINK_RE.search('[text](target.md "My Title")')
        self.assertIsNotNone(m)
        self.assertEqual(m.group(2), "target.md")

    def test_link_with_fragment(self):
        m = LINK_RE.search("[text](doc.md#section)")
        self.assertIsNotNone(m)
        self.assertEqual(m.group(2), "doc.md#section")

    def test_no_match_on_image(self):
        # Image links (![...](url)) contain the same syntax — LINK_RE will match
        # the inner part; they should be treated as pass-through by callers.
        m = LINK_RE.search("![alt](image.png)")
        # The regex matches the inner ](url) portion — callers must handle images.
        self.assertIsNotNone(m)


class TestMachinePathRE(unittest.TestCase):
    def test_file_uri(self):
        self.assertTrue(MACHINE_PATH_RE.search("file:///Users/alice/project"))

    def test_macos_path(self):
        self.assertTrue(MACHINE_PATH_RE.search("/Users/alice/project"))

    def test_linux_path(self):
        self.assertTrue(MACHINE_PATH_RE.search("/home/alice/project"))

    def test_windows_path_single_backslash(self):
        self.assertTrue(MACHINE_PATH_RE.search("C:\\Users\\alice"))

    def test_github_url_not_flagged(self):
        self.assertFalse(
            MACHINE_PATH_RE.search("https://github.com/danielvm-git/bigpowers")
        )


class TestRewriteLinksForPi(unittest.TestCase):
    """Tests run without a real repo tree — path existence is irrelevant here;
    we only verify that the URL construction logic is correct."""

    NAME = "my-skill"

    def _rw(self, body):
        return rewrite_links_for_pi(body, self.NAME)

    def test_external_link_untouched(self):
        body = "[docs](https://example.com)"
        self.assertEqual(self._rw(body), body)

    def test_anchor_only_untouched(self):
        body = "[section](#heading)"
        self.assertEqual(self._rw(body), body)

    def test_absolute_path_untouched(self):
        body = "[root](/absolute/path.md)"
        self.assertEqual(self._rw(body), body)

    def test_relative_link_repointed(self):
        body = "[ref](REFERENCE.md)"
        result = self._rw(body)
        # Must not contain the original bare target
        self.assertNotIn("](REFERENCE.md)", result)
        # Must be a relative path targeting the skills source tree
        self.assertIn("REFERENCE.md", result)

    def test_fragment_preserved(self):
        body = "[section](REFERENCE.md#anchor)"
        result = self._rw(body)
        self.assertIn("#anchor", result)
        # Fragment must not be mangled into a path component
        self.assertNotIn("anchor" + os.sep, result)

    def test_link_with_title_attribute(self):
        body = '[ref](REFERENCE.md "My Title")'
        result = self._rw(body)
        # Must not be left unrewritten
        self.assertNotIn("](REFERENCE.md", result)

    def test_code_block_links_not_rewritten(self):
        body = "Real: [ref](REFERENCE.md)\n\n```\n[fake](nowhere.md)\n```\n"
        result = self._rw(body)
        # The real link should be rewritten
        self.assertNotIn("](REFERENCE.md)", result)
        # The code-block link must be untouched
        self.assertIn("[fake](nowhere.md)", result)

    def test_inline_code_link_not_rewritten(self):
        body = "Example: `[x](bad.md)` — real [ref](REFERENCE.md)."
        result = self._rw(body)
        self.assertIn("[x](bad.md)", result)  # inline code preserved
        self.assertNotIn("](REFERENCE.md)", result)  # real link rewritten


class TestResolveBash(unittest.TestCase):
    """Regression: dispatch must not make subprocess resolve the bare name
    'bash'. On Windows the Win32 CreateProcess search order finds the WSL
    stub in System32 before Git Bash on PATH, so setup aborted with
    'Windows Subsystem for Linux has no installed distributions'."""

    def test_env_override_wins(self):
        with mock.patch.dict(os.environ, {"BIGPOWERS_BASH": "/custom/bash"}):
            self.assertEqual(_srp.resolve_bash(), "/custom/bash")

    def test_uses_path_resolved_bash(self):
        env = {k: v for k, v in os.environ.items() if k != "BIGPOWERS_BASH"}
        with mock.patch.dict(os.environ, env, clear=True):
            with mock.patch.object(_srp.shutil, "which", return_value="/usr/bin/bash"):
                self.assertEqual(_srp.resolve_bash(), "/usr/bin/bash")

    def test_falls_back_to_bare_bash(self):
        env = {k: v for k, v in os.environ.items() if k != "BIGPOWERS_BASH"}
        with mock.patch.dict(os.environ, env, clear=True):
            with mock.patch.object(_srp.shutil, "which", return_value=None):
                self.assertEqual(_srp.resolve_bash(), "bash")


class TestDispatchUsesResolvedBash(unittest.TestCase):
    """The adapter subprocess must receive the PATH-resolved bash path, not
    the bare name that Windows resolves to the WSL stub."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.repo_root = self._tmp.name
        adapter_dir = os.path.join(self.repo_root, "scripts", "adapters")
        os.makedirs(adapter_dir)
        self.adapter = os.path.join(adapter_dir, "fake.sh")
        with open(self.adapter, "w", encoding="utf-8") as f:
            f.write("#!/usr/bin/env bash\n")

    def tearDown(self):
        self._tmp.cleanup()

    def test_dispatch_passes_resolved_bash_to_popen(self):
        captured = {}

        class _FakeProc:
            returncode = 0

            def communicate(self, input=None):
                return ("", "")

        def _fake_popen(cmd, **kwargs):
            captured["cmd"] = cmd
            return _FakeProc()

        sentinel = os.path.join(self.repo_root, "git-bash")
        with mock.patch.object(_srp, "resolve_bash", return_value=sentinel):
            with mock.patch.object(_srp.subprocess, "Popen", side_effect=_fake_popen):
                _srp.dispatch_to_adapter({"name": "x"}, "fake", self.repo_root)

        self.assertEqual(captured["cmd"][0], sentinel)
        self.assertEqual(captured["cmd"][1], self.adapter)


if __name__ == "__main__":
    unittest.main()
