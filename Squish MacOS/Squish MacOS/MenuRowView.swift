import AppKit

/// Generic menu row used for plain text items (Blocked websites, Quit) and the
/// non-interactive "Squish" header. Shares the same 14pt leading padding as
/// LinkMenuItemView and ToggleMenuItemView so every row in the menu lines up.
final class MenuRowView: NSView {

    enum Style {
        case header  // small grey label, non-interactive
        case action  // standard 13pt label, hoverable
    }

    static let actionHeight: CGFloat = 22
    static let headerHeight: CGFloat = 22

    private let style: Style
    private let leftLabel: NSTextField
    private let rightLabel: NSTextField?

    private var trackingArea: NSTrackingArea?
    private var wasHighlighted: Bool = false

    init(leftText: String, rightText: String? = nil, style: Style = .action) {
        self.style = style
        let width = LinkMenuItemView.preferredWidth
        let height = (style == .header) ? Self.headerHeight : Self.actionHeight

        leftLabel = NSTextField(labelWithString: leftText)
        switch style {
        case .header:
            leftLabel.font = .systemFont(ofSize: 11, weight: .regular)
            leftLabel.textColor = .tertiaryLabelColor
        case .action:
            leftLabel.font = .systemFont(ofSize: 13)
            leftLabel.textColor = .labelColor
        }
        leftLabel.lineBreakMode = .byTruncatingTail

        if let rightText {
            let label = NSTextField(labelWithString: rightText)
            label.font = .systemFont(ofSize: 13)
            label.textColor = .tertiaryLabelColor
            label.alignment = .right
            label.lineBreakMode = .byTruncatingHead
            rightLabel = label
        } else {
            rightLabel = nil
        }

        super.init(frame: NSRect(x: 0, y: 0, width: width, height: height))

        let leftPadding: CGFloat = 14
        let rightPadding: CGFloat = 14
        let labelHeight: CGFloat = 18
        let labelY: CGFloat = (height - labelHeight) / 2

        let leftWidth = ceil(leftLabel.fittingSize.width)
        leftLabel.frame = NSRect(x: leftPadding, y: labelY, width: leftWidth, height: labelHeight)
        addSubview(leftLabel)

        if let rightLabel {
            let rightX = leftPadding + leftWidth + 12
            let rightWidth = max(0, width - rightX - rightPadding)
            rightLabel.frame = NSRect(x: rightX, y: labelY, width: rightWidth, height: labelHeight)
            rightLabel.autoresizingMask = [.width]
            addSubview(rightLabel)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        guard style == .action else { return }
        if let area = trackingArea { removeTrackingArea(area) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func draw(_ dirtyRect: NSRect) {
        guard style == .action else { return }

        let isHighlighted = enclosingMenuItem?.isHighlighted ?? false

        if isHighlighted {
            NSColor.selectedMenuItemColor.setFill()
            let rect = bounds.insetBy(dx: 5, dy: 1)
            NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4).fill()
        }

        if isHighlighted != wasHighlighted {
            wasHighlighted = isHighlighted
            leftLabel.textColor = isHighlighted ? .selectedMenuItemTextColor : .labelColor
            rightLabel?.textColor = isHighlighted
                ? NSColor.selectedMenuItemTextColor.withAlphaComponent(0.75)
                : .tertiaryLabelColor
        }
    }

    override func mouseEntered(with event: NSEvent) {
        guard style == .action else { return }
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        guard style == .action else { return }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard style == .action,
              let menuItem = enclosingMenuItem,
              let menu = menuItem.menu else { return }
        menu.cancelTracking()
        if let action = menuItem.action {
            // Pass target as-is — it may be nil (e.g. Quit relies on
            // NSApplication.terminate(_:) being resolved via the responder
            // chain). sendAction(to: nil, from:) walks the chain for us.
            NSApp.sendAction(action, to: menuItem.target, from: menuItem)
        }
    }
}
