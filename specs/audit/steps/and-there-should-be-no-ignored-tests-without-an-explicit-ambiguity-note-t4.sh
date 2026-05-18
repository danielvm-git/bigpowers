#!/usr/bin/env bash
# And there should be no "Ignored Tests" without an explicit ambiguity note (T4)
# Verification: T4 prohibition is present in CONVENTIONS.md and develop-tdd/SKILL.md
grep -q "T4" CONVENTIONS.md && grep -q "T4" develop-tdd/SKILL.md
