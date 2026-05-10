import AppKit

/// First-run welcome window. Shown automatically the first time the app
/// launches (gated by the `squish.hasSeenWelcome` UserDefaults flag) and
/// also reachable from the menu.
final class WelcomeWindowController: NSWindowController {

    static let shared = WelcomeWindowController()

    private static let seenKey = "squish.hasSeenWelcome"

    static var hasSeen: Bool {
        get { UserDefaults.standard.bool(forKey: seenKey) }
        set { UserDefaults.standard.set(newValue, forKey: seenKey) }
    }

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 440),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Squish"
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)
        buildContent()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildContent() {
        guard let content = window?.contentView else { return }

        // App icon — 88pt centered near the top
        let iconImage = NSImage(named: "AppIcon") ?? NSApp.applicationIconImage
        let iconView = NSImageView(image: iconImage ?? NSImage())
        iconView.frame = NSRect(x: (460 - 88) / 2, y: 320, width: 88, height: 88)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        content.addSubview(iconView)

        // Title
        let title = NSTextField(labelWithString: "Welcome to Squish")
        title.font = .systemFont(ofSize: 22, weight: .semibold)
        title.alignment = .center
        title.frame = NSRect(x: 20, y: 280, width: 420, height: 30)
        content.addSubview(title)

        // Tagline
        let tagline = NSTextField(labelWithString: "Your URLs, squished automatically.")
        tagline.font = .systemFont(ofSize: 13)
        tagline.textColor = .secondaryLabelColor
        tagline.alignment = .center
        tagline.frame = NSRect(x: 20, y: 254, width: 420, height: 20)
        content.addSubview(tagline)

        // Feature rows
        let features: [(symbol: String, text: String)] = [
            ("doc.on.clipboard",
             "Copy any URL longer than 40 characters and Squish replaces it on your clipboard with a TinyURL short link."),
            ("menubar.rectangle",
             "Your last 5 short links live in the menu bar — click any to copy it again."),
            ("hand.raised",
             "Trusted domains like GitHub, AWS and Supabase are skipped. Add more from \u{201C}Blocked websites\u{201D}.")
        ]

        var y: CGFloat = 220
        for (symbol, text) in features {
            let row = makeFeatureRow(symbolName: symbol, text: text, width: 420)
            row.frame.origin = NSPoint(x: 20, y: y - row.frame.height)
            content.addSubview(row)
            y -= row.frame.height + 10
        }

        // Get started button
        let button = NSButton(title: "Get Started", target: self, action: #selector(getStartedTapped))
        button.bezelStyle = .rounded
        button.keyEquivalent = "\r"   // default action — pulses & accepts Return
        button.frame = NSRect(x: (460 - 120) / 2, y: 24, width: 120, height: 32)
        content.addSubview(button)
    }

    private func makeFeatureRow(symbolName: String, text: String, width: CGFloat) -> NSView {
        let row = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 44))

        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let icon = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(symbolConfig)
        let iconView = NSImageView(image: icon ?? NSImage())
        iconView.contentTintColor = .controlAccentColor
        iconView.frame = NSRect(x: 8, y: 10, width: 28, height: 24)
        row.addSubview(iconView)

        let label = NSTextField(wrappingLabelWithString: text)
        label.font = .systemFont(ofSize: 12)
        label.textColor = .labelColor
        label.frame = NSRect(x: 48, y: 0, width: width - 56, height: 44)
        row.addSubview(label)

        return row
    }

    @objc private func getStartedTapped() {
        Self.hasSeen = true
        close()
    }
}
