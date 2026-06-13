#!/usr/bin/env bash
# Given the codebase exists
if [[ -d "audit-code" ]]; then
  exit 0
else
  exit 1
fi
