#!/usr/bin/env bash
#
# Build, sign, notarize, staple, and package Roulette as a distributable DMG.
#
# Prerequisites (one-time):
#   1. Apple Developer Program membership.
#   2. A "Developer ID Application" certificate installed in your login keychain.
#   3. A notarytool credential profile stored in the keychain:
#        xcrun notarytool store-credentials "RouletteNotary" \
#          --apple-id "you@example.com" --team-id "ABCDE12345" \
#          --password "app-specific-password"
#   4. (optional) create-dmg:  brew install create-dmg
#
# Usage:
#   TEAM_ID=ABCDE12345 NOTARY_PROFILE=RouletteNotary ./scripts/build-release.sh
#
set -euo pipefail

# --- Config (override via env) ----------------------------------------------
SCHEME="Roulette"
APP_NAME="Roulette"
CONFIG="Release"
TEAM_ID="${TEAM_ID:?Set TEAM_ID to your 10-char Apple Developer Team ID}"
NOTARY_PROFILE="${NOTARY_PROFILE:?Set NOTARY_PROFILE to your notarytool keychain profile name}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT}/build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_DIR="${BUILD_DIR}/export"
APP_PATH="${EXPORT_DIR}/${APP_NAME}.app"
DMG_PATH="${BUILD_DIR}/${APP_NAME}.dmg"

echo "==> Regenerating Xcode project"
( cd "${ROOT}" && xcodegen generate )

echo "==> Generating ExportOptions.plist (developer-id)"
EXPORT_PLIST="${BUILD_DIR}/ExportOptions.plist"
mkdir -p "${BUILD_DIR}"
cat > "${EXPORT_PLIST}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>developer-id</string>
  <key>teamID</key><string>${TEAM_ID}</string>
  <key>signingStyle</key><string>automatic</string>
</dict>
</plist>
PLIST

echo "==> Archiving"
xcodebuild archive \
  -project "${ROOT}/${APP_NAME}.xcodeproj" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIG}" \
  -destination 'generic/platform=macOS' \
  -archivePath "${ARCHIVE_PATH}" \
  DEVELOPMENT_TEAM="${TEAM_ID}"

echo "==> Exporting Developer ID-signed app"
rm -rf "${EXPORT_DIR}"
xcodebuild -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportOptionsPlist "${EXPORT_PLIST}" \
  -exportPath "${EXPORT_DIR}"

echo "==> Notarizing (submitting ${APP_NAME}.app)"
# notarytool needs a zip/dmg; zip the app for submission.
NOTARIZE_ZIP="${BUILD_DIR}/${APP_NAME}-notarize.zip"
ditto -c -k --keepParent "${APP_PATH}" "${NOTARIZE_ZIP}"
xcrun notarytool submit "${NOTARIZE_ZIP}" \
  --keychain-profile "${NOTARY_PROFILE}" \
  --wait

echo "==> Stapling ticket"
xcrun stapler staple "${APP_PATH}"
xcrun stapler validate "${APP_PATH}"

echo "==> Building DMG"
rm -f "${DMG_PATH}"
if command -v create-dmg >/dev/null 2>&1; then
  create-dmg \
    --volname "${APP_NAME}" \
    --window-size 540 380 \
    --icon "${APP_NAME}.app" 150 180 \
    --app-drop-link 390 180 \
    "${DMG_PATH}" "${EXPORT_DIR}"
else
  echo "    create-dmg not found; falling back to hdiutil (no fancy layout)"
  hdiutil create -volname "${APP_NAME}" -srcfolder "${EXPORT_DIR}" -ov -format UDZO "${DMG_PATH}"
fi

echo "==> Notarizing the DMG too (so the download itself passes Gatekeeper)"
xcrun notarytool submit "${DMG_PATH}" --keychain-profile "${NOTARY_PROFILE}" --wait
xcrun stapler staple "${DMG_PATH}"

echo ""
echo "Done: ${DMG_PATH}"
echo "Verify with:  spctl -a -vvv -t install \"${APP_PATH}\""
