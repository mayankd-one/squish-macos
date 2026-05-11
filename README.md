# Squish

A tiny macOS menu bar app that auto-shortens long URLs the moment you copy them.

> Copy a long URL. Get a short one. No tab-switching, no website.

## What it does

- 📋 Anytime you copy a URL longer than 40 characters, Squish quietly shortens it via TinyURL and replaces what's on your clipboard with the short link.
- 🪶 Lives in your menu bar — out of the way until you need it.
- 🔁 Your last 5 short links are one click away from the menu, ready to re-copy.
- 🛡️ Trusted domains (GitHub, AWS, Supabase, etc.) are left alone. You can add your own from **Blocked websites**.
- 🔔 Optional notification + sound on every successful squish.

## Install

1. Download the latest **`Squish-1.0.dmg`** from [Releases](https://github.com/mayankd-one/squish-macos/releases).
2. Open the DMG and drag **Squish** onto **Applications**.
3. **First launch only** — see below.

### First launch — important

Squish is signed with an Apple Development certificate (not a paid Developer ID), so the first time you double-click it macOS Gatekeeper will refuse with *"Apple could not verify… is free of malware."* You only have to bypass this **once per Mac**. Pick whichever you prefer:

**Option A — right-click in Finder (no Terminal):**
1. Open **Applications** in Finder.
2. *Right-click* (or Control-click) **Squish** → choose **Open**.
3. Click **Open** in the warning dialog.
4. Squish launches. macOS now trusts it forever on this Mac — double-clicking works from now on.

**Option B — one-line Terminal (preferred if you're sharing the DMG):**
```bash
xattr -dr com.apple.quarantine /Applications/Squish.app
open /Applications/Squish.app
```

Or use the helper bundled in this repo:
```bash
./scripts/clear-quarantine.sh
```

This is the standard "indie macOS app" dance and goes away the moment the app picks up a paid Apple Developer ID + notarization. It is *not* required again after the first successful launch.

## Using Squish

- **Status bar icon**: the `><` mark in your menu bar. Click it to open the menu.
- **The last 5 squishes** sit at the top — click any to copy that short link back to your clipboard.
- **Notifications** toggle: enables/disables the system notification (+ sound) on each new squish.
- **Clear history**: wipes the 5 stored short links.
- **About Squish**: re-opens the welcome screen.
- **Blocked websites**: edit the domain allow-list (defaults include GitHub, AWS, Supabase, Vercel, Railway, localhost, etc.).

## Building from source

Requirements: macOS 26 (Tahoe) or later, Xcode 17+.

```bash
git clone https://github.com/mayankd-one/squish-macos.git
cd squish-macos
open "Squish MacOS/Squish MacOS.xcodeproj"
# Press ⌘R in Xcode
```

### Building a DMG

```bash
./scripts/build-dmg.sh
# → dist/Squish-1.0.dmg
```

The script:
1. Builds a Release `Squish MacOS.app` via `xcodebuild`
2. Renames it to `Squish.app` for the install window
3. Stages it alongside a `/Applications` symlink
4. Strips quarantine xattrs from the staged copy
5. Packages everything as a compressed read-only DMG

Build is staged in `/tmp` to keep iCloud's File Provider from tagging the bundle with xattrs that trip `codesign`.

## Project layout

```
Squish MacOS/        # Xcode project + sources
  App Icons/         # 1024px source PNGs (app + menu bar)
  Squish MacOS/      # Swift sources, assets
scripts/
  build-dmg.sh       # one-command Release build → installer
  clear-quarantine.sh# Gatekeeper first-launch helper
dist/                # built .dmg lands here (gitignored)
```

## Tech

- **Swift + AppKit**, no third-party dependencies
- **TinyURL** for the actual shortening (free, no API key)
- Clipboard polled via `NSPasteboard.changeCount` every 0.5s
- History stored in `UserDefaults` as JSON

## License

MIT.
