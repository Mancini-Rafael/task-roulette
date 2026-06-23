#!/usr/bin/env bash
#
# Build and launch Roulette from source — no Apple Developer account needed.
# The app is ad-hoc signed, which is enough to run locally on your own Mac.
#
# Prerequisites: macOS 14+, Xcode 16+, and XcodeGen (`brew install xcodegen`).
#
# Usage:  ./scripts/run.sh            (Debug)
#         CONFIG=Release ./scripts/run.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${CONFIG:-Debug}"
DERIVED="${ROOT}/build/DerivedData"
APP="${DERIVED}/Build/Products/${CONFIG}/Roulette.app"

cd "${ROOT}"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "error: XcodeGen not found. Install it with:  brew install xcodegen" >&2
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "error: Xcode not found. Install Xcode from the App Store, then run:" >&2
  echo "       sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  exit 1
fi

echo "==> Generating Xcode project"
xcodegen generate

echo "==> Building (${CONFIG}, ad-hoc signed)"
xcodebuild \
  -project Roulette.xcodeproj \
  -scheme Roulette \
  -configuration "${CONFIG}" \
  -destination 'platform=macOS' \
  -derivedDataPath "${DERIVED}" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=YES \
  build

echo "==> Launching ${APP}"
# Relaunch cleanly if a previous instance is running.
pkill -x Roulette >/dev/null 2>&1 || true
open "${APP}"

echo ""
echo "Roulette is running — look for the 🎲 icon in your menu bar."
echo "Default hotkeys: ⌃⌥Space to open, ⌃⌥R to spin."
