import AppKit

final class ToggleMenuItemView: NSView {

    static let preferredHeight: CGFloat = 30

    private let label: NSTextField
    private let switchControl: NSSwitch
    private let onToggle: (Bool) -> Void

    private var trackingArea: NSTrackingArea?
    private var wasHighlighted: Bool = false

    init(text: String, isOn: Bool, onToggle: @escaping (Bool) -> Void) {
        self.onToggle = onToggle
        let width = LinkMenuItemView.preferredWidth
        let height = Self.preferredHeight

        label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 13)
        label.textColor = .labelColor

        switchControl = NSSwitch()
        switchControl.state = isOn ? .on : .off
        switchControl.controlSize = .mini

        super.init(frame: NSRect(x: 0, y: 0, width: width, height: height))

        switchControl.target = self
        switchControl.action = #selector(switchChanged)

        let leftPadding: CGFloat = 14
        let textRightPadding: CGFloat = 14
        // NSSwitch has ~6pt of internal padding around its visible track,
        // so use a smaller right inset to make the switch's track align
        // flush with the text right edge of the other rows.
        let switchRightPadding: CGFloat = 6
        let labelHeight: CGFloat = 18

        label.frame = NSRect(
            x: leftPadding,
            y: (height - labelHeight) / 2,
            width: width - leftPadding - textRightPadding,
            height: labelHeight
        )

        let switchSize = switchControl.fittingSize
        switchControl.frame = NSRect(
            x: width - switchRightPadding - switchSize.width,
            y: (height - switchSize.height) / 2,
            width: switchSize.width,
            height: switchSize.height
        )
        switchControl.autoresizingMask = [.minXMargin]

        addSubview(label)
        addSubview(switchControl)
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func switchChanged() {
        onToggle(switchControl.state == .on)
    }

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
            label.textColor = isHighlighted ? .selectedMenuItemTextColor : .labelColor
        }
    }

    override func mouseEntered(with event: NSEvent) { needsDisplay = true }
    override func mouseExited(with event: NSEvent)  { needsDisplay = true }

    override func mouseUp(with event: NSEvent) {
        // If the click landed on the switch itself, NSSwitch has already
        // toggled its own state and fired switchChanged(). Doing it again
        // here would silently undo that toggle, so bail out.
        let location = convert(event.locationInWindow, from: nil)
        guard !switchControl.frame.contains(location) else { return }

        // Click was on the row outside the switch — toggle programmatically.
        switchControl.state = (switchControl.state == .on) ? .off : .on
        onToggle(switchControl.state == .on)
    }
}
