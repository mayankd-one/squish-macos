# Squish — Xcode Setup Guide

## Prerequisites
- macOS 13+ (Ventura or later)
- Xcode 15+
- Apple ID (free — needed to sign the app so macOS allows it to run)

---

## Step 1 — Create the Xcode project

1. Open Xcode → **File > New > Project**
2. Choose **macOS > App** → Next
3. Fill in:
   - **Product Name:** Squish
   - **Team:** Your Apple ID (sign in via Xcode > Settings > Accounts if needed)
   - **Bundle Identifier:** com.yourname.squish
   - **Interface:** SwiftUI
   - **Language:** Swift
   - Uncheck "Include Tests"
4. Save the project **inside** this folder (`my apps/squish/`)

---

## Step 2 — Replace the generated files

Delete these auto-generated files Xcode created:
- `ContentView.swift` (delete — we don't use a window)

Then drag **all 5 `.swift` files** from the `Squish/` folder into the Xcode project navigator:
- `SquishApp.swift`
- `AppDelegate.swift`
- `StatusBarController.swift`
- `ClipboardMonitor.swift`
- `URLShortener.swift`
- `NotificationManager.swift`

When prompted, make sure **"Copy items if needed"** is checked and the **Squish target** is selected.

> If Xcode already generated a `SquishApp.swift`, replace its contents with the one from this folder.

---

## Step 3 — Hide the Dock icon (LSUIElement)

1. Click on `Info.plist` in the project navigator
2. Click the `+` button on any row to add a new key
3. Type: `Application is agent (UIElement)`
4. Set type to **Boolean** and value to **YES**

Alternatively, right-click `Info.plist` → "Open As > Source Code" and add:
```xml
<key>LSUIElement</key>
<true/>
```

---

## Step 4 — Add the outgoing network entitlement

The app needs to call the TinyURL API over HTTPS.

1. In the project navigator, click the **Squish** target → **Signing & Capabilities**
2. Confirm "App Sandbox" is listed. If it is:
   - Check **"Outgoing Connections (Client)"** under Network

If App Sandbox is not present, HTTPS calls work by default — skip this step.

---

## Step 5 — Build & Run

Press **⌘R**. The app will launch with:
- A ✂ icon in the menu bar
- No Dock icon
- A notification permission prompt on first run — click **Allow**

---

## Testing

1. Copy any full URL (e.g. `https://www.apple.com/mac-mini/`)
2. Wait ~0.5 seconds
3. Paste anywhere — you should see a `tinyurl.com/…` link
4. A macOS notification should appear

---

## Troubleshooting

| Problem | Fix |
|---|---|
| No menu bar icon | Make sure `LSUIElement = YES` is set in Info.plist |
| URLs not being shortened | Check Outgoing Connections is enabled in Signing & Capabilities |
| No notifications | Go to System Settings > Notifications > Squish and enable banners |
| macOS blocks the app on first open | Right-click the built app → Open → Open anyway |
