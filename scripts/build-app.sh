#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="HumanizeBar"
APP_DIR="${PROJECT_DIR}/${APP_NAME}.app"
ICON_PATH="${PROJECT_DIR}/shared/Resources/AppIcon.icns"

echo "Building ${APP_NAME}..."
cd "$PROJECT_DIR"
swift build -c release --target HumanizeBar

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# Copy binary
cp ".build/release/${APP_NAME}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"

# Copy Info.plist
cp "macos/Info.plist" "${APP_DIR}/Contents/"

if [[ ! -f "${ICON_PATH}" ]]; then
    echo "Error: missing app icon at ${ICON_PATH}" >&2
    echo "Run: bash scripts/generate-app-icons.sh" >&2
    exit 1
fi

# Copy app icon
cp "${ICON_PATH}" "${APP_DIR}/Contents/Resources/AppIcon.icns"

# Ad-hoc code sign
echo "Signing..."
codesign --force --sign - "$APP_DIR"

echo "Done: ${APP_DIR}"
echo "Run with: open ${APP_DIR}"
