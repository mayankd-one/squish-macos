#!/usr/bin/env swift
// Generates a 660x400 DMG background image with the Squish app icon on the
// left, an arrow pointing right, and a label hint for the Applications drop
// target. Saves to dmg-background.png + @2x next to this script.

import AppKit
import CoreGraphics

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0])
    .deletingLastPathComponent()
let repoRoot = scriptDir.deletingLastPathComponent()

let appIconPath = repoRoot
    .appendingPathComponent("Squish MacOS")
    .appendingPathComponent("App Icons")
    .appendingPathComponent("squish-icon-default.png")

guard let appIcon = NSImage(contentsOfFile: appIconPath.path) else {
    fputs("error: could not load app icon at \(appIconPath.path)\n", stderr)
    exit(1)
}

let width: CGFloat = 660
let height: CGFloat = 400
let scale: CGFloat = 2

func renderBackground(into bitmap: NSBitmapImageRep) {
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    // Background — soft vertical gradient
    let bgGradient = NSGradient(colors: [
        NSColor(white: 0.99, alpha: 1),
        NSColor(white: 0.93, alpha: 1)
    ])!
    bgGradient.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)

    // Title
    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
        .foregroundColor: NSColor(white: 0.15, alpha: 1)
    ]
    let title = NSAttributedString(
        string: "Drag Squish to your Applications folder",
        attributes: titleAttrs
    )
    let titleSize = title.size()
    title.draw(at: NSPoint(x: (width - titleSize.width) / 2, y: height - 60))

    // Squish app icon on the left. No text label is drawn — Finder will
    // render the .app's filename underneath the icon in the install window;
    // a baked-in label would stack on top of it.
    let iconRect = NSRect(x: 100, y: 110, width: 128, height: 128)
    appIcon.draw(in: iconRect)

    // Arrow
    let arrowColor = NSColor(white: 0.55, alpha: 1)
    arrowColor.setStroke()
    arrowColor.setFill()

    let arrowPath = NSBezierPath()
    let arrowY: CGFloat = 174
    let arrowStartX: CGFloat = 270
    let arrowEndX: CGFloat = 410
    arrowPath.move(to: NSPoint(x: arrowStartX, y: arrowY))
    arrowPath.line(to: NSPoint(x: arrowEndX, y: arrowY))
    arrowPath.lineWidth = 4
    arrowPath.lineCapStyle = .round
    arrowPath.stroke()

    let head = NSBezierPath()
    head.move(to: NSPoint(x: arrowEndX, y: arrowY))
    head.line(to: NSPoint(x: arrowEndX - 14, y: arrowY + 10))
    head.line(to: NSPoint(x: arrowEndX - 14, y: arrowY - 10))
    head.close()
    head.fill()

    // Applications target on the right. Same reason as above — Finder will
    // label the symlink itself, no baked-in caption.
    let appsURL = URL(fileURLWithPath: "/Applications")
    let appsIcon = NSWorkspace.shared.icon(forFile: appsURL.path)
    appsIcon.size = NSSize(width: 128, height: 128)
    appsIcon.draw(in: NSRect(x: 432, y: 110, width: 128, height: 128))
}

// @2x rendering
let bitmap2x = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(width * scale),
    pixelsHigh: Int(height * scale),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
bitmap2x.size = NSSize(width: width, height: height)
renderBackground(into: bitmap2x)

let out2x = scriptDir.appendingPathComponent("dmg-background@2x.png")
try bitmap2x.representation(using: .png, properties: [:])!.write(to: out2x)

// @1x rendering
let bitmap1x = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(width),
    pixelsHigh: Int(height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
renderBackground(into: bitmap1x)

let out1x = scriptDir.appendingPathComponent("dmg-background.png")
try bitmap1x.representation(using: .png, properties: [:])!.write(to: out1x)

print("wrote: \(out1x.path)")
print("wrote: \(out2x.path)")
