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

        // Header
        let titleItem = NSMenuItem(title: "Squish", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        titleItem.attributedTitle = NSAttributedString(
            string: "Squish",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        menu.addItem(titleItem)
        menu.addItem(.separator())

        // URL history
        let history = HistoryManager.shared.items
        if history.isEmpty {
            let emptyItem = NSMenuItem(
                title: "Copy a URL to squish it",
                action: nil,
                keyEquivalent: ""
            )
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for (index, entry) in history.enumerated() {
                menu.addItem(buildHistoryItem(entry: entry, index: index))
            }
        }

        menu.addItem(.separator())

        // Notifications toggle
        let notifItem = NSMenuItem(
            title: "Notifications",
            action: #selector(toggleNotifications),
            keyEquivalent: ""
        )
        notifItem.target = self
        notifItem.state = NotificationManager.shared.isEnabled ? .on : .off
        menu.addItem(notifItem)

        // Blocked websites
        let blockedItem = NSMenuItem(
            title: "Blocked websites",
            action: #selector(openBlockedDomains),
            keyEquivalent: ""
        )
        blockedItem.target = self
        menu.addItem(blockedItem)

        menu.addItem(.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
    }

    private func buildHistoryItem(entry: HistoryEntry, index: Int) -> NSMenuItem {
        let item = NSMenuItem()

        let linkLabel = String(format: "link %02d", index + 1)
        let host = entry.siteName.isEmpty
            ? (URL(string: entry.original)?.host ?? "")
            : entry.siteName

        let attributed = NSMutableAttributedString()

        attributed.append(NSAttributedString(
            string: linkLabel,
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                .foregroundColor: NSColor.labelColor
            ]
        ))

        // Right-align the site name using a tab stop trick via padding
        let padding = String(repeating: " ", count: max(1, 24 - linkLabel.count))
        attributed.append(NSAttributedString(
            string: padding,
            attributes: [.font: NSFont.systemFont(ofSize: 13)]
        ))

        attributed.append(NSAttributedString(
            string: host,
            attributes: [
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: NSColor.tertiaryLabelColor
            ]
        ))

        item.attributedTitle = attributed
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

    @objc private func toggleNotifications() {
        NotificationManager.shared.isEnabled.toggle()
        refresh()
    }

    @objc private func openBlockedDomains() {
        BlockedDomainsWindowController.shared.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
