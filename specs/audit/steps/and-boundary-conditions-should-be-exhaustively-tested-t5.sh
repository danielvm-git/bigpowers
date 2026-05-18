#!/usr/bin/env bash
# And boundary conditions should be exhaustively tested (T5)
# Verification: T5 mandate is present in CONVENTIONS.md and develop-tdd/SKILL.md
grep -q "T5" CONVENTIONS.md && grep -q "T5" develop-tdd/SKILL.md
