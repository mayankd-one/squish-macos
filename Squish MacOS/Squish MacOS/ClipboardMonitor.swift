import AppKit

class ClipboardMonitor {

    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private let onURL: (String) -> Void

    // Hosts whose shortened URLs we should not re-shorten
    private let shortenerHosts = ["tinyurl.com", "bit.ly", "t.co", "goo.gl", "ow.ly", "short.io", "rb.gy"]

    init(onURL: @escaping (String) -> Void) {
        self.onURL = onURL
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        guard
            let raw = pb.string(forType: .string),
            let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines)),
            url.scheme == "http" || url.scheme == "https"
        else { return }

        let urlString = url.absoluteString

        // Already short enough — leave it alone
        guard urlString.count >= 40 else { return }

        // Already a shortened link
        if let host = url.host?.lowercased(),
           shortenerHosts.contains(where: { host == $0 || host.hasSuffix(".\($0)") }) {
            return
        }

        // Blocked domain
        guard !BlockedDomainsManager.shared.isBlocked(urlString) else { return }

        onURL(urlString)
    }
}
