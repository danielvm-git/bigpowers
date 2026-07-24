#!/usr/bin/env bash
# story: e64s01
# BeforeTool wrapper — RTK command rewrite (optional; passthrough when rtk absent).
set -euo pipefail

if command -v rtk >/dev/null 2>&1; then
  if rtk hook gemini 2>/dev/null; then
    exit 0
  fi
  if rtk hook claude 2>/dev/null; then
    exit 0
  fi
fi
exit 0
