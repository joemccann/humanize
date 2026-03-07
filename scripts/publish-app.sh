#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

APP_NAME="HumanizeBar"
APP_BUNDLE_NAME="${APP_NAME}.app"
DIST_DIR="${PROJECT_DIR}/dist"
APP_DIR="${DIST_DIR}/${APP_BUNDLE_NAME}"
ZIP_PATH="${DIST_DIR}/${APP_NAME}.zip"
APPLICATIONS_PATH="/Applications/${APP_BUNDLE_NAME}"
ICON_PATH="${PROJECT_DIR}/shared/Resources/AppIcon.icns"

SIGNING_IDENTITY="${PUBLISH_SIGNING_IDENTITY:-}"
NOTARY_PROFILE="${PUBLISH_NOTARY_PROFILE:-}"
SKIP_NOTARIZATION=0

usage() {
    cat <<EOF
Usage: bash scripts/publish-app.sh [options]

Build, sign, optionally notarize, and install ${APP_BUNDLE_NAME} to /Applications.
This script is intended for production packaging (not ad-hoc development builds).

Options:
  --signing-identity <value>  Developer ID Application certificate name.
                              Default: \$PUBLISH_SIGNING_IDENTITY
  --notary-profile <value>    notarytool keychain profile name.
                              Default: \$PUBLISH_NOTARY_PROFILE
  --skip-notarization         Skip notarization + stapling.
  -h, --help                  Show this help message.

Examples:
  PUBLISH_SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" \\
  PUBLISH_NOTARY_PROFILE="AC_NOTARY_PROFILE" \\
  bash scripts/publish-app.sh

  bash scripts/publish-app.sh --skip-notarization --signing-identity "Developer ID Application: Your Name (TEAMID)"
EOF
}

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: required command not found: $cmd" >&2
        exit 1
    fi
}

require_value() {
    local option="$1"
    local value="${2:-}"
    if [[ -z "${value}" || "${value}" == --* ]]; then
        echo "Error: ${option} requires a value." >&2
        usage
        exit 1
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --signing-identity)
            require_value "$1" "${2:-}"
            SIGNING_IDENTITY="${2:-}"
            shift 2
            ;;
        --notary-profile)
            require_value "$1" "${2:-}"
            NOTARY_PROFILE="${2:-}"
            shift 2
            ;;
        --skip-notarization)
            SKIP_NOTARIZATION=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if [[ -z "${SIGNING_IDENTITY}" ]]; then
    echo "Error: missing signing identity." >&2
    echo "Set PUBLISH_SIGNING_IDENTITY or pass --signing-identity." >&2
    exit 1
fi

if [[ "${SKIP_NOTARIZATION}" -eq 0 && -z "${NOTARY_PROFILE}" ]]; then
    echo "Error: missing notary profile." >&2
    echo "Set PUBLISH_NOTARY_PROFILE or pass --notary-profile (or use --skip-notarization)." >&2
    exit 1
fi

require_command swift
require_command codesign
require_command ditto
require_command xcrun

echo "Publishing ${APP_NAME} from ${PROJECT_DIR}"
cd "${PROJECT_DIR}"

echo "1/7 Build release binary"
swift build -c release --target HumanizeBar

echo "2/7 Create clean app bundle in dist/"
rm -rf "${APP_DIR}" "${ZIP_PATH}"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"
cp ".build/release/${APP_NAME}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
cp "macos/Info.plist" "${APP_DIR}/Contents/"

if [[ ! -f "${ICON_PATH}" ]]; then
    echo "Error: missing app icon at ${ICON_PATH}" >&2
    echo "Run: bash scripts/generate-app-icons.sh" >&2
    exit 1
fi

cp "${ICON_PATH}" "${APP_DIR}/Contents/Resources/AppIcon.icns"

echo "3/7 Sign app with Developer ID: ${SIGNING_IDENTITY}"
codesign --force --timestamp --options runtime --sign "${SIGNING_IDENTITY}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
codesign --force --timestamp --options runtime --sign "${SIGNING_IDENTITY}" "${APP_DIR}"

echo "4/7 Verify code signing"
codesign --verify --deep --strict --verbose=2 "${APP_DIR}"

if [[ "${SKIP_NOTARIZATION}" -eq 0 ]]; then
    echo "5/7 Zip + notarize app"
    ditto -c -k --keepParent "${APP_DIR}" "${ZIP_PATH}"
    xcrun notarytool submit "${ZIP_PATH}" --keychain-profile "${NOTARY_PROFILE}" --wait

    echo "6/7 Staple notarization ticket"
    xcrun stapler staple "${APP_DIR}"
else
    echo "5/7 Notarization skipped"
    echo "6/7 Stapling skipped"
fi

echo "7/7 Install app to /Applications"
if [[ -w "/Applications" ]]; then
    ditto "${APP_DIR}" "${APPLICATIONS_PATH}"
else
    echo "Administrator privileges required to write to /Applications."
    sudo ditto "${APP_DIR}" "${APPLICATIONS_PATH}"
fi

echo "Publish complete."
echo "App bundle: ${APP_DIR}"
echo "Installed to: ${APPLICATIONS_PATH}"
