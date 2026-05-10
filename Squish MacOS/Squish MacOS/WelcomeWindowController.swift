import AppKit

/// First-run welcome window. Shown automatically on first launch (gated by
/// `squish.hasSeenWelcome` UserDefaults) and reachable from the menu's
/// "About Squish" row.
///
/// Layout matches the Figma "Startup Screen" frame: 600×586, light grey
/// background, three white feature cards, dark gradient pill button.
/// Container view is flipped so positions map 1:1 to Figma top-down coords.
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

        // Replace contentView with a flipped container so all subview frames
        // use Figma's top-down coordinate system.
        let container = FlippedView(frame: NSRect(x: 0, y: 0, width: 600, height: 586))
        window.contentView = container
        buildContent(in: container)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Layout (Figma top-down y, container is flipped)

    private func buildContent(in container: NSView) {

        // App icon — Figma (252, 60, 96, 96)
        let iconImage = NSImage(named: "AppIcon") ?? NSApp.applicationIconImage
        let iconView = NSImageView(image: iconImage ?? NSImage())
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.frame = NSRect(x: 252, y: 60, width: 96, height: 96)
        container.addSubview(iconView)

        // Title "Squish" — Figma y=176, full-width centred
        container.addSubview(centredLabel(
            "Squish",
            font: .systemFont(ofSize: 32, weight: .bold),
            color: .black,
            kern: -1.28,
            frame: NSRect(x: 0, y: 176, width: 600, height: 38)
        ))

        // Tagline — Figma y=216
        container.addSubview(centredLabel(
            "Your URLs, shortened automatically.",
            font: .systemFont(ofSize: 14, weight: .semibold),
            color: NSColor(white: 0.4, alpha: 1),  // #666
            kern: -0.28,
            frame: NSRect(x: 0, y: 216, width: 600, height: 20)
        ))

        // Three feature cards — Figma y=274, x=40 / 220 / 400
        let cards: [(asset: String, text: String, x: CGFloat)] = [
            ("WelcomeIcon-Copy",   "Copy a long URL.\nAnd get back a short one.", 40),
            ("WelcomeIcon-Save",   "Your last 5 squishes, ready to re-copy.",     220),
            ("WelcomeIcon-Shield", "Tell Squish which sites to leave alone.",     400)
        ]
        for (asset, text, x) in cards {
            let card = WelcomeFeatureCard(iconAsset: asset, text: text)
            card.frame = NSRect(x: x, y: 274, width: 160, height: 144)
            container.addSubview(card)
        }

        // Button — Figma (220, 458, 160, 46), centred horizontally
        let button = GradientPillButton(title: "Get started") { [weak self] in
            self?.getStartedTapped()
        }
        button.frame = NSRect(x: 220, y: 458, width: 160, height: 46)
        container.addSubview(button)
    }

    private func centredLabel(
        _ text: String,
        font: NSFont,
        color: NSColor,
        kern: CGFloat,
        frame: NSRect
    ) -> NSTextField {
        // Paragraph style with .center is what *actually* centres an attributed
        // string label. The text field's `alignment` property is ignored when
        // the value is set via attributedStringValue / labelWithAttributedString.
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let attributed = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .kern: kern,
                .paragraphStyle: paragraph
            ]
        )
        let label = NSTextField(labelWithAttributedString: attributed)
        label.alignment = .center
        label.frame = frame
        return label
    }

    @objc private func getStartedTapped() {
        Self.hasSeen = true
        close()
    }
}

// MARK: - Helpers

/// Container view with top-down y axis so subview frames match Figma directly.
private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

// MARK: - Feature card

private final class WelcomeFeatureCard: NSView {

    init(iconAsset: String, text: String) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        layer?.cornerRadius = 24
        layer?.cornerCurve = .continuous

        // Icon at Figma (20, 20, 24, 24) — vector SVG with gradient baked in,
        // so no tint applied.
        let iconView = NSImageView(image: NSImage(named: iconAsset) ?? NSImage())
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.frame = NSRect(x: 20, y: 20, width: 24, height: 24)
        addSubview(iconView)

        // Body text at Figma (20, 68, 120, 54) — give some extra height for safety
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.25
        let attributed = NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: NSColor.black,
            .kern: -0.28,
            .paragraphStyle: paragraph
        ])
        let label = NSTextField(labelWithAttributedString: attributed)
        label.maximumNumberOfLines = 0
        label.usesSingleLineMode = false
        label.lineBreakMode = .byWordWrapping
        label.frame = NSRect(x: 20, y: 68, width: 120, height: 64)
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { true }
}

// MARK: - Gradient pill button (custom NSView, not NSButton)

private final class GradientPillButton: NSView {

    private let titleLabel = NSTextField(labelWithString: "")
    private let gradientLayer = CAGradientLayer()
    private let onClick: () -> Void

    init(title: String, onClick: @escaping () -> Void) {
        self.onClick = onClick
        super.init(frame: .zero)

        wantsLayer = true
        layer?.cornerRadius = 16
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = true

        gradientLayer.colors = [
            NSColor(red: 0.302, green: 0.302, blue: 0.302, alpha: 1).cgColor, // #4D4D4D
            NSColor.black.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        layer?.addSublayer(gradientLayer)

        titleLabel.stringValue = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.alignment = .center
        addSubview(titleLabel)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        gradientLayer.frame = bounds
        let h = ceil(titleLabel.fittingSize.height)
        titleLabel.frame = NSRect(
            x: 0,
            y: (bounds.height - h) / 2,
            width: bounds.width,
            height: h
        )
    }

    override func mouseUp(with event: NSEvent) {
        onClick()
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}
