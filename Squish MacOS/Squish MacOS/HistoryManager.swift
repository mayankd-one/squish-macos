import Foundation

struct HistoryEntry: Codable {
    let original: String
    let shortened: String
    let siteName: String
    let date: Date
}

class HistoryManager {

    static let shared = HistoryManager()

    private let storageKey = "squish.history"
    private let maxItems = 5

    private(set) var items: [HistoryEntry] = []

    private init() { load() }

    func clear() {
        items = []
        save()
    }

    func add(original: String, shortened: String, siteName: String) {
        // Avoid storing the same shortened URL twice
        guard !items.contains(where: { $0.shortened == shortened }) else { return }

        let entry = HistoryEntry(
            original: original,
            shortened: shortened,
            siteName: siteName,
            date: Date()
        )
        items.insert(entry, at: 0)
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        save()
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data)
        else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
