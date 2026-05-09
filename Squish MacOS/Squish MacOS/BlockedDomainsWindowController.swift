import AppKit

class BlockedDomainsWindowController: NSWindowController,
                                      NSTableViewDataSource,
                                      NSTableViewDelegate {

    static let shared = BlockedDomainsWindowController()

    private var tableView: NSTableView!
    private var addField: NSTextField!
    private var domains: [String] = []

    private init() {
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 420),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Blocked Websites"
        window.center()
        window.minSize = NSSize(width: 320, height: 300)
        super.init(window: window)
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func showWindow(_ sender: Any?) {
        domains = BlockedDomainsManager.shared.domains.sorted()
        tableView.reloadData()
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
    }

    private func buildUI() {
        guard let content = window?.contentView else { return }

        // Bottom toolbar
        let toolbar = NSView(frame: NSRect(x: 0, y: 0, width: 380, height: 50))
        toolbar.autoresizingMask = [.width]

        let separator = NSBox(frame: NSRect(x: 0, y: 49, width: 380, height: 1))
        separator.boxType = .separator
        separator.autoresizingMask = [.width]
        toolbar.addSubview(separator)

        addField = NSTextField(frame: NSRect(x: 12, y: 13, width: 220, height: 24))
        addField.placeholderString = "example.com"
        addField.cell?.sendsActionOnEndEditing = false
        addField.target = self
        addField.action = #selector(addDomain)
        toolbar.addSubview(addField)

        let addBtn = NSButton(title: "Add", target: self, action: #selector(addDomain))
        addBtn.frame = NSRect(x: 240, y: 13, width: 60, height: 24)
        addBtn.bezelStyle = .rounded
        addBtn.keyEquivalent = "\r"
        toolbar.addSubview(addBtn)

        let removeBtn = NSButton(title: "Remove", target: self, action: #selector(removeDomain))
        removeBtn.frame = NSRect(x: 308, y: 13, width: 62, height: 24)
        removeBtn.bezelStyle = .rounded
        toolbar.addSubview(removeBtn)

        content.addSubview(toolbar)

        // Scroll + table
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 50, width: 380, height: 370))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder

        tableView = NSTableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = true
        tableView.headerView = nil
        tableView.rowHeight = 22
        tableView.gridStyleMask = []

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("domain"))
        col.resizingMask = .autoresizingMask
        tableView.addTableColumn(col)

        scrollView.documentView = tableView
        content.addSubview(scrollView)
    }

    @objc private func addDomain() {
        let raw = addField.stringValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")

        guard !raw.isEmpty, !domains.contains(raw) else { return }
        domains.append(raw)
        domains.sort()
        BlockedDomainsManager.shared.domains = domains
        tableView.reloadData()
        addField.stringValue = ""
    }

    @objc private func removeDomain() {
        let selected = tableView.selectedRowIndexes
        guard !selected.isEmpty else { return }
        domains.remove(atOffsets: IndexSet(selected))
        BlockedDomainsManager.shared.domains = domains
        tableView.reloadData()
    }

    // MARK: NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int { domains.count }

    func tableView(
        _ tableView: NSTableView,
        objectValueFor tableColumn: NSTableColumn?,
        row: Int
    ) -> Any? {
        domains[row]
    }
}
