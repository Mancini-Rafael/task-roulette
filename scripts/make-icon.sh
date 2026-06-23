#!/usr/bin/env bash
#
# Generates the AppIcon asset catalog from the CoreGraphics renderer:
# renders a 1024 master, downscales to every macOS size, writes Contents.json.
#
# Usage:  ./scripts/make-icon.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICONSET="${ROOT}/Sources/Assets.xcassets/AppIcon.appiconset"
mkdir -p "${ICONSET}"

MASTER="${ICONSET}/icon-1024.png"
echo "==> Rendering master"
swift "${ROOT}/scripts/make-icon.swift" "${MASTER}"

echo "==> Downscaling"
for px in 512 256 128 64 32 16; do
  sips -z "${px}" "${px}" "${MASTER}" --out "${ICONSET}/icon-${px}.png" >/dev/null
done

# A preview for the README.
cp "${MASTER}" "${ROOT}/docs/icon.png"

echo "==> Writing Contents.json"
cat > "${ICONSET}/Contents.json" <<'JSON'
{
  "images" : [
    { "idiom" : "mac", "size" : "16x16",   "scale" : "1x", "filename" : "icon-16.png" },
    { "idiom" : "mac", "size" : "16x16",   "scale" : "2x", "filename" : "icon-32.png" },
    { "idiom" : "mac", "size" : "32x32",   "scale" : "1x", "filename" : "icon-32.png" },
    { "idiom" : "mac", "size" : "32x32",   "scale" : "2x", "filename" : "icon-64.png" },
    { "idiom" : "mac", "size" : "128x128", "scale" : "1x", "filename" : "icon-128.png" },
    { "idiom" : "mac", "size" : "128x128", "scale" : "2x", "filename" : "icon-256.png" },
    { "idiom" : "mac", "size" : "256x256", "scale" : "1x", "filename" : "icon-256.png" },
    { "idiom" : "mac", "size" : "256x256", "scale" : "2x", "filename" : "icon-512.png" },
    { "idiom" : "mac", "size" : "512x512", "scale" : "1x", "filename" : "icon-512.png" },
    { "idiom" : "mac", "size" : "512x512", "scale" : "2x", "filename" : "icon-1024.png" }
  ],
  "info" : { "version" : 1, "author" : "xcode" }
}
JSON

cat > "${ROOT}/Sources/Assets.xcassets/Contents.json" <<'JSON'
{ "info" : { "version" : 1, "author" : "xcode" } }
JSON

echo "Done: ${ICONSET}"
