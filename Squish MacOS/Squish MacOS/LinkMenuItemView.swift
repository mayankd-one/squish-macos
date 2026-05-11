import AppKit

final class LinkMenuItemView: NSView {

    static let preferredWidth: CGFloat = 260
    static let preferredHeight: CGFloat = 22

    private let leftLabel: NSTextField
    private let rightLabel: NSTextField

    private var trackingArea: NSTrackingArea?
    private var wasHighlighted: Bool = false

    init(leftText: String, rightText: String) {
        let width = Self.preferredWidth
        let height = Self.preferredHeight

        leftLabel = NSTextField(labelWithString: leftText)
        leftLabel.font = .systemFont(ofSize: 13)
        leftLabel.textColor = .labelColor
        leftLabel.lineBreakMode = .byTruncatingTail

        rightLabel = NSTextField(labelWithString: rightText)
        rightLabel.font = .systemFont(ofSize: 13)
        rightLabel.textColor = .tertiaryLabelColor
        rightLabel.alignment = .right
        rightLabel.lineBreakMode = .byTruncatingHead

        super.init(frame: NSRect(x: 0, y: 0, width: width, height: height))

        let leftPadding: CGFloat = 14
        let rightPadding: CGFloat = 14
        let labelHeight: CGFloat = 18
        let labelY: CGFloat = (height - labelHeight) / 2

        let leftWidth = ceil(leftLabel.fittingSize.width)
        leftLabel.frame = NSRect(x: leftPadding, y: labelY, width: leftWidth, height: labelHeight)

        let rightX = leftPadding + leftWidth + 12
        let rightWidth = max(0, width - rightX - rightPadding)
        rightLabel.frame = NSRect(x: rightX, y: labelY, width: rightWidth, height: labelHeight)
        rightLabel.autoresizingMask = [.width]

        addSubview(leftLabel)
        addSubview(rightLabel)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
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
        let isHighlighted = enclosingMenuItem?.isHighlighted ?? false

        if isHighlighted {
            NSColor.selectedMenuItemColor.setFill()
            let rect = bounds.insetBy(dx: 5, dy: 1)
            NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4).fill()
        }

        if isHighlighted != wasHighlighted {
            wasHighlighted = isHighlighted
            leftLabel.textColor = isHighlighted ? .selectedMenuItemTextColor : .labelColor
            rightLabel.textColor = isHighlighted
                ? NSColor.selectedMenuItemTextColor.withAlphaComponent(0.75)
                : .tertiaryLabelColor
        }
    }

    override func mouseEntered(with event: NSEvent) { needsDisplay = true }
    override func mouseExited(with event: NSEvent)  { needsDisplay = true }

    override func mouseUp(with event: NSEvent) {
        guard let menuItem = enclosingMenuItem,
              let menu = menuItem.menu else { return }
        menu.cancelTracking()
        if let action = menuItem.action {
            // Pass target as-is — nil is fine, sendAction(to: nil) walks
            // the responder chain.
            NSApp.sendAction(action, to: menuItem.target, from: menuItem)
        }
    }
}
