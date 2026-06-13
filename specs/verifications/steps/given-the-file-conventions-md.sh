#!/usr/bin/env bash
# Given the file CONVENTIONS.md
if [[ -f "CONVENTIONS.md" ]]; then
  exit 0
else
  echo "CONVENTIONS.md not found"
  exit 1
fi
