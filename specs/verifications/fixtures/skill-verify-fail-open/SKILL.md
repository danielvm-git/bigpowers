---
name: skill-verify-fail-open-fixture
description: Negative-path fixture for run-skill-verify.sh — must never PASS.
---

# Skill-verify fail-open fixture

Deliberately broken verify directives for negative-path self-test (issue #96).

→ verify: `test -f /nonexistent/path/for/skill-verify-self-test && echo OK || echo FAIL`
