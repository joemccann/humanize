#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

RESOURCES_DIR="${PROJECT_DIR}/Resources"
SOURCE_PNG="${RESOURCES_DIR}/AppIcon-1024.png"
ICONSET_DIR="${RESOURCES_DIR}/AppIcon.iconset"
ICNS_PATH="${RESOURCES_DIR}/AppIcon.icns"

usage() {
    cat <<USAGE
Usage: bash scripts/generate-app-icons.sh [--source <path>] [--help]

Generate macOS app icon assets from a 1024x1024 (or larger square) PNG source.

Options:
  --source <path>  Source master PNG. Default: Resources/AppIcon-1024.png
  -h, --help       Show this help message.
USAGE
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

parse_dimension() {
    local key="$1"
    local file="$2"
    sips -g "$key" "$file" 2>/dev/null | awk '/pixel/{print $2}' | tail -n 1
}

resize_png() {
    local size="$1"
    local name="$2"
    sips -z "${size}" "${size}" "${SOURCE_PNG}" --out "${ICONSET_DIR}/${name}" >/dev/null
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            require_value "$1" "${2:-}"
            SOURCE_PNG="$2"
            shift 2
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

require_command sips
require_command iconutil

if [[ ! -f "${SOURCE_PNG}" ]]; then
    echo "Error: source icon not found: ${SOURCE_PNG}" >&2
    exit 1
fi

width="$(parse_dimension pixelWidth "${SOURCE_PNG}")"
height="$(parse_dimension pixelHeight "${SOURCE_PNG}")"

if [[ -z "${width}" || -z "${height}" ]]; then
    echo "Error: failed to read source image dimensions." >&2
    exit 1
fi

if [[ "${width}" != "${height}" ]]; then
    echo "Error: source image must be square. Got ${width}x${height}." >&2
    exit 1
fi

if (( width < 1024 )); then
    echo "Error: source image must be at least 1024x1024. Got ${width}x${height}." >&2
    exit 1
fi

mkdir -p "${RESOURCES_DIR}"
rm -rf "${ICONSET_DIR}"
mkdir -p "${ICONSET_DIR}"

echo "Generating iconset from ${SOURCE_PNG} ..."
resize_png 16 icon_16x16.png
resize_png 32 icon_16x16@2x.png
resize_png 32 icon_32x32.png
resize_png 64 icon_32x32@2x.png
resize_png 128 icon_128x128.png
resize_png 256 icon_128x128@2x.png
resize_png 256 icon_256x256.png
resize_png 512 icon_256x256@2x.png
resize_png 512 icon_512x512.png
resize_png 1024 icon_512x512@2x.png

echo "Compiling icns..."
iconutil -c icns "${ICONSET_DIR}" -o "${ICNS_PATH}"

echo "Generated icon assets:"
echo "- Source: ${SOURCE_PNG}"
echo "- Iconset: ${ICONSET_DIR}"
echo "- ICNS: ${ICNS_PATH}"
