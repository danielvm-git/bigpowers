#!/usr/bin/env bash
# Falsification fixture — must always exit 1.
# If the harness reports PASS for this step, the harness itself is broken.
echo "FALSIFICATION: This step intentionally fails to verify the harness honours non-zero exit codes."
exit 1
