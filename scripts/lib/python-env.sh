#!/usr/bin/env bash
# story: BUG-2026-07-04-python-interpreter-fragility
# Resolve a Python interpreter that is guaranteed to have PyYAML
# and other requirements.txt dependencies.
# Source this script, then use $PYTHON instead of bare python3.
#
# Resolution order:
#   1. .venv/bin/python3 (project virtualenv, if present)
#   2. pyenv shim (if active)
#   3. python3 on PATH

resolve_python() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  local venv_python="$script_dir/.venv/bin/python3"

  if [ -x "$venv_python" ]; then
    PYTHON="$venv_python"
  elif command -v python3 >/dev/null 2>&1; then
    PYTHON="python3"
  else
    echo "python-env: ERROR — no python3 found anywhere" >&2
    echo "  Tried: $venv_python, python3 on PATH" >&2
    return 1
  fi

  # Verify PyYAML is available
  if ! "$PYTHON" -c "import yaml" 2>/dev/null; then
    echo "python-env: WARN — $PYTHON lacks PyYAML" >&2
    echo "  Run: pip install -r requirements.txt" >&2
    # Fall back to PATH python3 if .venv one doesn't work
    if [ "$PYTHON" = "$venv_python" ] && command -v python3 >/dev/null 2>&1; then
      if python3 -c "import yaml" 2>/dev/null; then
        PYTHON="python3"
        echo "python-env: Fallback to PATH python3 (has PyYAML)" >&2
      fi
    fi
  fi

  export PYTHON
  echo "python-env: Using $PYTHON" >&2
}

resolve_python
