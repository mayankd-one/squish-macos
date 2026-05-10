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
        let rightPadding: CGFloat = 14
        let labelHeight: CGFloat = 18

        label.frame = NSRect(
            x: leftPadding,
            y: (height - labelHeight) / 2,
            width: 200,
            height: labelHeight
        )

        let switchSize = switchControl.fittingSize
        switchControl.frame = NSRect(
            x: width - rightPadding - switchSize.width,
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
        // Toggle when row is clicked anywhere outside the switch itself
        let newState: NSControl.StateValue = switchControl.state == .on ? .off : .on
        switchControl.state = newState
        onToggle(newState == .on)
    }
}
