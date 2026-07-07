import AppKit

final class ToggleMenuItemView: NSView {

    static let preferredHeight: CGFloat = 30

    private let label: NSTextField
    private let toggle: AccentToggle
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

        toggle = AccentToggle(isOn: isOn)

        super.init(frame: NSRect(x: 0, y: 0, width: width, height: height))

        toggle.onToggle = { [weak self] newValue in
            self?.onToggle(newValue)
        }

        let leftPadding: CGFloat = 14
        let textRightPadding: CGFloat = 14
        let switchRightPadding: CGFloat = 14
        let labelHeight: CGFloat = 18

        label.frame = NSRect(
            x: leftPadding,
            y: (height - labelHeight) / 2,
            width: width - leftPadding - textRightPadding,
            height: labelHeight
        )

        let toggleSize = toggle.intrinsicContentSize
        toggle.frame = NSRect(
            x: width - switchRightPadding - toggleSize.width,
            y: (height - toggleSize.height) / 2,
            width: toggleSize.width,
            height: toggleSize.height
        )
        toggle.autoresizingMask = [.minXMargin]

        addSubview(label)
        addSubview(toggle)
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
            label.textColor = isHighlighted ? .selectedMenuItemTextColor : .labelColor
        }
    }

    override func mouseEntered(with event: NSEvent) { needsDisplay = true }
    override func mouseExited(with event: NSEvent)  { needsDisplay = true }

    override func mouseUp(with event: NSEvent) {
        // If the click landed on the toggle itself, it has already handled
        // the state change. Toggling again here would undo it, so bail out.
        let location = convert(event.locationInWindow, from: nil)
        guard !toggle.frame.contains(location) else { return }

        // Click was on the row outside the toggle — toggle programmatically.
        toggle.setOn(!toggle.isOn, notify: true)
    }
}

/// A small custom toggle that always paints its ON state with the system
/// accent colour. Unlike NSSwitch, it does not desaturate when its host
/// window is inactive — which is exactly what happens to NSSwitch inside a
/// menu, leaving the "on" switch a washed-out grey.
final class AccentToggle: NSView {

    private(set) var isOn: Bool
    var onToggle: ((Bool) -> Void)?

    // Dimensions tuned to sit next to 13pt menu text, similar to a mini switch.
    private let trackWidth: CGFloat = 30
    private let trackHeight: CGFloat = 18
    private let knobInset: CGFloat = 2

    init(isOn: Bool) {
        self.isOn = isOn
        super.init(frame: NSRect(x: 0, y: 0, width: trackWidth, height: trackHeight))
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize {
        NSSize(width: trackWidth, height: trackHeight)
    }

    override var isFlipped: Bool { false }

    func setOn(_ newValue: Bool, notify: Bool) {
        guard newValue != isOn else {
            if notify { onToggle?(isOn) }
            return
        }
        isOn = newValue
        needsDisplay = true
        if notify { onToggle?(isOn) }
    }

    override func draw(_ dirtyRect: NSRect) {
        let track = bounds
        let radius = track.height / 2

        // Track — accent when on, neutral grey when off.
        let trackColor: NSColor = isOn
            ? .controlAccentColor
            : NSColor.tertiaryLabelColor
        trackColor.setFill()
        NSBezierPath(roundedRect: track, xRadius: radius, yRadius: radius).fill()

        // Knob — white circle, left when off, right when on.
        let knobDiameter = track.height - knobInset * 2
        let knobX = isOn
            ? track.maxX - knobInset - knobDiameter
            : track.minX + knobInset
        let knobRect = NSRect(
            x: knobX,
            y: track.minY + knobInset,
            width: knobDiameter,
            height: knobDiameter
        )

        // Subtle shadow under the knob for depth.
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
        shadow.shadowOffset = NSSize(width: 0, height: -0.5)
        shadow.shadowBlurRadius = 1
        shadow.set()
        NSColor.white.setFill()
        NSBezierPath(ovalIn: knobRect).fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    override func mouseDown(with event: NSEvent) {
        // Consume the down so the enclosing view doesn't also react; the
        // actual toggle happens on mouseUp for a natural click feel.
    }

    override func mouseUp(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        if bounds.contains(location) {
            setOn(!isOn, notify: true)
        }
    }
}
