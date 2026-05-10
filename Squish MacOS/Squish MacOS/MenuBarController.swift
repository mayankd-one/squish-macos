import AppKit

class MenuBarController: NSObject {

    private var statusItem: NSStatusItem!
    private var menu: NSMenu!

    override init() {
        super.init()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            // Custom template image — black silhouette tinted by the menu bar
            // appearance. Imageset is marked template via Contents.json so the
            // alpha channel becomes the mask regardless of source colour.
            let icon = NSImage(named: "MenuBarIcon")
            icon?.isTemplate = true
            icon?.accessibilityDescription = "Squish"
            button.image = icon
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

        // "Squish" header — custom view so it left-aligns with all other rows
        let titleItem = NSMenuItem()
        titleItem.view = MenuRowView(leftText: "Squish", style: .header)
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

        let aboutItem = NSMenuItem()
        aboutItem.view = MenuRowView(leftText: "About Squish")
        aboutItem.action = #selector(openWelcome)
        aboutItem.target = self
        menu.addItem(aboutItem)

        let blockedItem = NSMenuItem()
        blockedItem.view = MenuRowView(leftText: "Blocked websites")
        blockedItem.action = #selector(openBlockedDomains)
        blockedItem.target = self
        menu.addItem(blockedItem)

        // "⌘Q" rendered as the right-side text. keyEquivalent kept so the
        // shortcut still works while the menu is open.
        let quitItem = NSMenuItem()
        quitItem.view = MenuRowView(leftText: "Quit", rightText: "\u{2318}Q")
        quitItem.action = #selector(NSApplication.terminate(_:))
        quitItem.keyEquivalent = "q"
        menu.addItem(quitItem)
    }

    private func buildHistoryItem(entry: HistoryEntry, index: Int) -> NSMenuItem {
        let item = NSMenuItem()
        // Show the shortened URL with the protocol stripped for a cleaner look
        // (e.g. "tinyurl.com/abc123" instead of "https://tinyurl.com/abc123").
        let leftText = entry.shortened
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        let rawSiteName = entry.siteName.isEmpty
            ? (URL(string: entry.original)?.host ?? "")
            : entry.siteName
        let withoutCom = rawSiteName.hasSuffix(".com")
            ? String(rawSiteName.dropLast(4))
            : rawSiteName
        let rightText = withoutCom.prefix(1).uppercased() + withoutCom.dropFirst()
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

    @objc private func openWelcome() {
        WelcomeWindowController.shared.showWindow(nil)
    }
}
