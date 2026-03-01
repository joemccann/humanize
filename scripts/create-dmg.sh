#!/usr/bin/env bash
set -euo pipefail

# Creates a DMG installer from a .app bundle.
# Usage: bash scripts/create-dmg.sh [path-to.app] [output-dmg-path]
#
# If no arguments are given, defaults to:
#   App:  HumanizeBar.app  (in project root)
#   DMG:  HumanizeBar.dmg  (in project root)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

APP_PATH="${1:-${PROJECT_DIR}/HumanizeBar.app}"
DMG_PATH="${2:-${PROJECT_DIR}/HumanizeBar.dmg}"
VOL_NAME="HumanizeBar"

if [[ ! -d "$APP_PATH" ]]; then
    echo "Error: app bundle not found at ${APP_PATH}" >&2
    echo "Build it first with: bash scripts/build-app.sh" >&2
    exit 1
fi

echo "Creating DMG from ${APP_PATH}..."

# Set up staging directory
STAGING_DIR=$(mktemp -d)
trap 'rm -rf "$STAGING_DIR"' EXIT

cp -R "$APP_PATH" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

# Remove any existing DMG
rm -f "$DMG_PATH"

# Create compressed DMG
hdiutil create \
    -volname "$VOL_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "Done: ${DMG_PATH}"
