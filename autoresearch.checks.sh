#!/bin/bash
set -euo pipefail
# Build only shared tests (avoids iOS UIKit errors), then run them
swift build --target HumanizeSharedTests 2>&1 | tail -3
swift test --skip-build --filter HumanizeSharedTests 2>&1 | tail -5
