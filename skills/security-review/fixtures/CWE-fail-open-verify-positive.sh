#!/usr/bin/env bash
# story: e80s05
# Positive fixture: fail-open verify directive (must be flagged)
# Vulnerable: exit 0 even when check fails via || echo
grep -q 'bigpowers' /nonexistent/path 2>/dev/null || echo "FAIL: missing artifact"
