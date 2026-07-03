#!/usr/bin/env bash
# And tests should verify behavior through public APIs, not implementation (T8)
# Verification: T8 mandate is present in CONVENTIONS.md and skills/develop-tdd/SKILL.md
grep -q "T8" CONVENTIONS.md && grep -q "T8" skills/develop-tdd/SKILL.md
