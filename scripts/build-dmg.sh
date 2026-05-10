#!/usr/bin/env bash
#
# Builds a Release Squish MacOS.app and packages it into a styled .dmg
# with a custom Finder window background and pre-positioned icons.
#
# Output: dist/Squish-1.0.dmg
#
# Build is staged under /tmp to avoid iCloud File Provider tagging the
# .app bundle with com.apple.FinderInfo / fpfs xattrs that trip codesign.

set -euo pipefail

# --------------------------- config ---------------------------
APP_NAME="Squish MacOS"
VOL_NAME="Squish"
DMG_VERSION="1.0"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$REPO_ROOT/Squish MacOS/Squish MacOS.xcodeproj"
SCHEME="$APP_NAME"
DERIVED="/tmp/squish-build/DerivedData"
STAGE="/tmp/squish-build/dmg-staging"
RW_DMG="/tmp/squish-build/Squish-rw.dmg"
DIST_DIR="$REPO_ROOT/dist"
FINAL_DMG="$DIST_DIR/Squish-${DMG_VERSION}.dmg"
BG_SOURCE="$REPO_ROOT/scripts/dmg-background.png"
BG_SOURCE_2X="$REPO_ROOT/scripts/dmg-background@2x.png"

WIN_W=660
WIN_H=400
ICON_SIZE=128

# --------------------------- preflight ------------------------
[[ -f "$BG_SOURCE" ]]    || { echo "missing $BG_SOURCE — run scripts/make-dmg-background.swift"; exit 1; }
[[ -f "$BG_SOURCE_2X" ]] || { echo "missing $BG_SOURCE_2X — run scripts/make-dmg-background.swift"; exit 1; }

# --------------------------- 1. Release build -----------------
echo "==> Cleaning previous build artifacts"
rm -rf /tmp/squish-build
mkdir -p /tmp/squish-build

echo "==> Building Release .app"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  build \
  | tail -3

APP_SRC="$DERIVED/Build/Products/Release/${APP_NAME}.app"
[[ -d "$APP_SRC" ]] || { echo "build did not produce $APP_SRC"; exit 1; }

# --------------------------- 2. Stage layout ------------------
echo "==> Staging DMG layout"
mkdir -p "$STAGE/.background"
cp -R "$APP_SRC" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
cp "$BG_SOURCE"    "$STAGE/.background/background.png"
cp "$BG_SOURCE_2X" "$STAGE/.background/background@2x.png"

# Strip stray xattrs in the staged copy
xattr -cr "$STAGE/${APP_NAME}.app"

# --------------------------- 3. RW DMG ------------------------
echo "==> Creating writable DMG"
rm -f "$RW_DMG"
hdiutil create \
  -srcfolder "$STAGE" \
  -volname "$VOL_NAME" \
  -fs HFS+ \
  -fsargs "-c c=64,a=16,e=16" \
  -format UDRW \
  "$RW_DMG" \
  >/dev/null

echo "==> Mounting RW DMG"
MOUNT_INFO="$(hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG")"
DEVICE="$(echo "$MOUNT_INFO" | grep '/Volumes/' | head -1 | awk '{print $1}')"
MOUNT="/Volumes/${VOL_NAME}"

# --------------------------- 4. Style window ------------------
echo "==> Configuring Finder window via AppleScript"
osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "${VOL_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 200 + ${WIN_W}, 120 + ${WIN_H}}

        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to ${ICON_SIZE}
        set background picture of viewOptions to file ".background:background.png"

        set position of item "${APP_NAME}.app" of container window to {165, 200}
        set position of item "Applications"     of container window to {496, 200}

        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

# Persist .DS_Store and unmount
sync
hdiutil detach "$DEVICE" >/dev/null

# --------------------------- 5. Compress to RO DMG ------------
echo "==> Converting to compressed read-only DMG"
mkdir -p "$DIST_DIR"
rm -f "$FINAL_DMG"
hdiutil convert "$RW_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$FINAL_DMG" \
  >/dev/null

# Cleanup
rm -f "$RW_DMG"

echo
echo "==> Done"
ls -lh "$FINAL_DMG"
