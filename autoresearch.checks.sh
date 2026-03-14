#!/bin/bash
set -euo pipefail
# Tests must pass — only show failures
swift test 2>&1 | grep -E "(error:|failed|FAIL|✘)" || true
# Check exit code of swift test
swift test --quiet 2>&1 | tail -5
