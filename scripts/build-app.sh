#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="HumanizeBar"
APP_DIR="${PROJECT_DIR}/${APP_NAME}.app"

echo "Building ${APP_NAME}..."
cd "$PROJECT_DIR"
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# Copy binary
cp ".build/release/${APP_NAME}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"

# Copy Info.plist
cp "Info.plist" "${APP_DIR}/Contents/"

# Ad-hoc code sign
echo "Signing..."
codesign --force --sign - "$APP_DIR"

echo "Done: ${APP_DIR}"
echo "Run with: open ${APP_DIR}"
