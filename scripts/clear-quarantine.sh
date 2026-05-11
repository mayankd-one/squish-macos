#!/usr/bin/env bash
#
# Strip the macOS quarantine flag from Squish so it launches on first try.
#
# Why this exists:
#   Squish is signed with an Apple Development certificate, not a Developer ID
#   notarized by Apple. Anything downloaded via a browser, Messages, AirDrop,
#   etc. gets a `com.apple.quarantine` extended attribute, and Gatekeeper
#   refuses to launch non-notarized apps that carry it. Running this script
#   removes that attribute on the installed app (or any path you pass in)
#   without disabling Gatekeeper system-wide.
#
# Usage:
#   ./clear-quarantine.sh                       # defaults to /Applications/Squish.app
#   ./clear-quarantine.sh /path/to/Squish.app   # or any path you want cleaned

set -euo pipefail

TARGET="${1:-/Applications/Squish.app}"

if [[ ! -e "$TARGET" ]]; then
  echo "error: $TARGET does not exist" >&2
  echo "       pass the path to Squish.app as the first argument, e.g."
  echo "       ./clear-quarantine.sh ~/Downloads/Squish.app"
  exit 1
fi

xattr -dr com.apple.quarantine "$TARGET" 2>/dev/null || true
echo "Cleared quarantine on: $TARGET"
echo "Squish should now launch normally."
