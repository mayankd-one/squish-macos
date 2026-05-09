import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var menuBarController: MenuBarController!
    private var clipboardMonitor: ClipboardMonitor!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationManager.shared.requestPermission()
        menuBarController = MenuBarController()
        clipboardMonitor = ClipboardMonitor { [weak self] url in
            self?.handleDetectedURL(url)
        }
        clipboardMonitor.start()
    }

    private func handleDetectedURL(_ urlString: String) {
        Task {
            guard let shortened = await URLShortener.shorten(urlString) else { return }
            let siteName = URL(string: urlString)?.host?
                .replacingOccurrences(of: "www.", with: "") ?? ""

            // Task inherits @MainActor isolation from AppDelegate — safe to update UI directly
            HistoryManager.shared.add(
                original: urlString,
                shortened: shortened,
                siteName: siteName
            )
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(shortened, forType: .string)
            menuBarController.refresh()
            NotificationManager.shared.send(original: urlString, shortened: shortened)
        }
    }
}
