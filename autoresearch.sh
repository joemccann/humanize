#!/bin/bash
set -euo pipefail

# Quick syntax check — must still compile
swift build 2>&1 | tail -5
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "METRIC overall=0"
  exit 1
fi

# Run evaluation
python3 eval/run_eval.py
