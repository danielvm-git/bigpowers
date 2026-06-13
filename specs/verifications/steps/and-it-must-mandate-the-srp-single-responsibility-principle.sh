#!/usr/bin/env bash
# And it must mandate the SRP (Single Responsibility Principle)
if grep -q "SRP" CONVENTIONS.md 2>/dev/null; then
  exit 0
else
  echo "CONVENTIONS.md does not mandate the SRP"
  exit 1
fi
