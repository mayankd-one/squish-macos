#!/usr/bin/env bash
#
# Builds a Release Squish.app and packages it into a .dmg with a minimal
# Finder window layout (icons positioned, toolbar hidden, no background).
#
# Output: dist/Squish-1.0.dmg
#
# Build is staged under /tmp to avoid iCloud File Provider tagging the
# .app bundle with com.apple.FinderInfo / fpfs xattrs that trip codesign.

set -euo pipefail

# --------------------------- config ---------------------------
# Xcode target name (used to find the build product).
APP_NAME="Squish MacOS"
# Friendly name the app ships under inside the DMG — what Finder shows as
# the icon label in the install window and what installs to /Applications.
SHIP_APP_NAME="Squish"
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

WIN_W=520
WIN_H=320
ICON_SIZE=128

# --------------------------- 1. Release build -----------------
echo "==> Cleaning previous build artifacts"
rm -rf /tmp/squish-build
mkdir -p /tmp/squish-build

# Detach any leftover Squish volumes from a previous run. Without this,
# hdiutil silently mounts the new one as "Squish 1" and our AppleScript
# below addresses the wrong (old) disk.
for vol in /Volumes/"${VOL_NAME}"*; do
  if [[ -d "$vol" ]]; then
    echo "==> Detaching leftover volume: $vol"
    hdiutil detach "$vol" >/dev/null 2>&1 || true
  fi
done

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
mkdir -p "$STAGE"
# Rename on the way in: build product is "Squish MacOS.app" but we ship it
# as "Squish.app" so the Finder label in the install window reads cleanly.
cp -R "$APP_SRC" "$STAGE/${SHIP_APP_NAME}.app"
ln -s /Applications "$STAGE/Applications"

# Strip stray xattrs in the staged copy, AND remove com.apple.quarantine
# specifically so this DMG (when used locally, not downloaded) installs
# an app that launches without the Gatekeeper "could not verify" dialog.
# If the DMG is later downloaded over a network, macOS will re-apply
# quarantine to the DMG itself; recipients then run scripts/clear-quarantine.sh
# (or right-click → Open) once. There's no way around that without a paid
# Apple Developer ID + notarization.
xattr -cr "$STAGE/${SHIP_APP_NAME}.app"
xattr -dr com.apple.quarantine "$STAGE/${SHIP_APP_NAME}.app" 2>/dev/null || true

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

        set position of item "${SHIP_APP_NAME}.app" of container window to {130, 150}
        set position of item "Applications"          of container window to {390, 150}

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
