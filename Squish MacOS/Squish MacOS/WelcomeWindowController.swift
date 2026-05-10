import AppKit

/// First-run welcome window. Shown automatically the first time the app
/// launches (gated by the `squish.hasSeenWelcome` UserDefaults flag) and
/// also reachable from the menu's "About Squish" row.
///
/// Layout matches the Figma "Startup Screen" frame: 600×586, light grey
/// background, three white feature cards, dark gradient pill button.
final class WelcomeWindowController: NSWindowController {

    static let shared = WelcomeWindowController()

    private static let seenKey = "squish.hasSeenWelcome"

    static var hasSeen: Bool {
        get { UserDefaults.standard.bool(forKey: seenKey) }
        set { UserDefaults.standard.set(newValue, forKey: seenKey) }
    }

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 586),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(white: 0.949, alpha: 1)  // #F2F2F2
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

    // MARK: - Layout

    private func buildContent() {
        guard let content = window?.contentView else { return }

        // App icon (Figma 252,60 → AppKit y = 586 - 60 - 96 = 430)
        let iconImage = NSImage(named: "AppIcon") ?? NSApp.applicationIconImage
        let iconView = NSImageView(image: iconImage ?? NSImage())
        iconView.frame = NSRect(x: 252, y: 430, width: 96, height: 96)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        content.addSubview(iconView)

        // Title "Squish" — y=176 → 586 - 176 - 32 = 378
        let title = NSTextField(labelWithAttributedString: NSAttributedString(
            string: "Squish",
            attributes: [
                .font: NSFont.systemFont(ofSize: 32, weight: .bold),
                .foregroundColor: NSColor.black,
                .kern: -1.28
            ]
        ))
        title.alignment = .center
        title.frame = NSRect(x: 0, y: 378, width: 600, height: 32)
        content.addSubview(title)

        // Tagline — y=216 → 586 - 216 - 18 = 352
        let tagline = NSTextField(labelWithAttributedString: NSAttributedString(
            string: "Your URLs, shortened automatically.",
            attributes: [
                .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: NSColor(white: 0.4, alpha: 1),  // #666
                .kern: -0.28
            ]
        ))
        tagline.alignment = .center
        tagline.frame = NSRect(x: 0, y: 352, width: 600, height: 18)
        content.addSubview(tagline)

        // Three feature cards in a row at y=274 → 586 - 274 - 144 = 168
        let cards: [(symbol: String, text: String, x: CGFloat)] = [
            ("doc.on.doc",                "Copy a long URL.\nAnd get back a short one.", 40),
            ("internaldrive",             "Your last 5 squishes, ready to re-copy.",     220),
            ("shield.lefthalf.filled",    "Tell Squish which sites to leave alone.",     400)
        ]
        for (symbol, text, x) in cards {
            let card = WelcomeFeatureCard(symbol: symbol, text: text)
            card.frame.origin = NSPoint(x: x, y: 168)
            content.addSubview(card)
        }

        // Get started button — y=458 → 586 - 458 - 46 = 82
        let button = GradientPillButton(
            title: "Get started",
            target: self,
            action: #selector(getStartedTapped)
        )
        button.frame = NSRect(x: 220, y: 82, width: 160, height: 46)
        content.addSubview(button)
    }

    @objc private func getStartedTapped() {
        Self.hasSeen = true
        close()
    }
}

// MARK: - Feature card

private final class WelcomeFeatureCard: NSView {

    init(symbol: String, text: String) {
        super.init(frame: NSRect(x: 0, y: 0, width: 160, height: 144))
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        layer?.cornerRadius = 24
        layer?.cornerCurve = .continuous

        // Icon — Figma (20,20,24,24) → AppKit y = 144 - 20 - 24 = 100
        let iconConfig = NSImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let icon = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(iconConfig)
        let iconView = NSImageView(image: icon ?? NSImage())
        iconView.contentTintColor = NSColor(white: 0.55, alpha: 1)
        iconView.frame = NSRect(x: 20, y: 100, width: 24, height: 24)
        addSubview(iconView)

        // Text — Figma (20,68,120,54) → AppKit y around 22, give 60pt height for safety
        let attributed = NSMutableAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: NSColor.black,
            .kern: -0.28
        ])
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.25
        attributed.addAttribute(
            .paragraphStyle,
            value: paragraph,
            range: NSRange(location: 0, length: attributed.length)
        )
        let label = NSTextField(labelWithAttributedString: attributed)
        label.maximumNumberOfLines = 0
        label.usesSingleLineMode = false
        label.lineBreakMode = .byWordWrapping
        label.frame = NSRect(x: 20, y: 18, width: 120, height: 64)
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Gradient pill button

private final class GradientPillButton: NSButton {

    private let gradientLayer = CAGradientLayer()

    init(title: String, target: AnyObject?, action: Selector?) {
        super.init(frame: .zero)
        self.target = target
        self.action = action
        self.isBordered = false
        self.bezelStyle = .smallSquare
        self.title = ""
        self.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: NSColor.white,
                .kern: -0.14
            ]
        )

        wantsLayer = true
        gradientLayer.colors = [
            NSColor(red: 0.302, green: 0.302, blue: 0.302, alpha: 1).cgColor, // #4D4D4D
            NSColor.black.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        gradientLayer.cornerRadius = 16
        gradientLayer.cornerCurve = .continuous
        layer = gradientLayer
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        gradientLayer.frame = bounds
    }
}
