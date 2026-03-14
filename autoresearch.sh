#!/bin/bash
set -euo pipefail

# Quick syntax check — shared library must compile (skip iOS/launcher targets)
swift build --target HumanizeShared 2>&1 | tail -5
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "METRIC overall=0"
  exit 1
fi

# Run evaluation
python3 eval/run_eval.py
