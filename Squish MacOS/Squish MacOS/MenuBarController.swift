import AppKit

class MenuBarController: NSObject {

    private var statusItem: NSStatusItem!
    private var menu: NSMenu!

    override init() {
        super.init()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "link.badge.plus",
                accessibilityDescription: "Squish"
            )
            button.image?.isTemplate = true
        }
        buildMenu()
        statusItem.menu = menu
    }

    func refresh() {
        buildMenu()
        statusItem.menu = menu
    }

    private func buildMenu() {
        menu = NSMenu()
        menu.minimumWidth = LinkMenuItemView.preferredWidth + 4

        // "Squish" header — small grey label, no separator after it
        let titleItem = NSMenuItem(title: "Squish", action: nil, keyEquivalent: "")
        titleItem.attributedTitle = NSAttributedString(
            string: "Squish",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: NSColor.tertiaryLabelColor
            ]
        )
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        // History rows
        let history = HistoryManager.shared.items
        if history.isEmpty {
            let empty = NSMenuItem()
            empty.view = LinkMenuItemView(leftText: "No links yet", rightText: "Copy a long URL")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            for (index, entry) in history.enumerated() {
                menu.addItem(buildHistoryItem(entry: entry, index: index))
            }
        }

        // Divider before Notifications
        menu.addItem(.separator())

        // Notifications toggle (custom row with NSSwitch)
        let notifItem = NSMenuItem()
        notifItem.view = ToggleMenuItemView(
            text: "Notifications",
            isOn: NotificationManager.shared.isEnabled,
            onToggle: { isOn in
                NotificationManager.shared.isEnabled = isOn
            }
        )
        menu.addItem(notifItem)

        // Divider before Blocked websites
        menu.addItem(.separator())

        let blockedItem = NSMenuItem(
            title: "Blocked websites",
            action: #selector(openBlockedDomains),
            keyEquivalent: ""
        )
        blockedItem.target = self
        menu.addItem(blockedItem)

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
    }

    private func buildHistoryItem(entry: HistoryEntry, index: Int) -> NSMenuItem {
        let item = NSMenuItem()
        let leftText = String(format: "link %02d", index + 1)
        let rightText = entry.siteName.isEmpty
            ? (URL(string: entry.original)?.host ?? "")
            : entry.siteName
        item.view = LinkMenuItemView(leftText: leftText, rightText: rightText)
        item.toolTip = entry.original
        item.representedObject = entry.shortened
        item.action = #selector(copyLink(_:))
        item.target = self
        return item
    }

    @objc private func copyLink(_ sender: NSMenuItem) {
        guard let shortened = sender.representedObject as? String else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(shortened, forType: .string)
    }

    @objc private func openBlockedDomains() {
        BlockedDomainsWindowController.shared.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
