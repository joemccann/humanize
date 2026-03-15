#!/bin/bash
set -euo pipefail

# Quick syntax check — shared library must compile (skip iOS/launcher targets)
swift build --target HumanizeShared 2>&1 | tail -5
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "METRIC overall=0"
  exit 1
fi

# Run evaluation
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/eval/run_eval.py"
