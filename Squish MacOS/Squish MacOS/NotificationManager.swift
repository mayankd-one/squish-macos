import UserNotifications
import AppKit

class NotificationManager {

    static let shared = NotificationManager()

    private let enabledKey = "squish.notifications.enabled"

    var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func send(original: String, shortened: String) {
        guard isEnabled else { return }

        let host = URL(string: original)?.host?
            .replacingOccurrences(of: "www.", with: "") ?? original

        let content = UNMutableNotificationContent()
        content.title = "Link squished!"
        content.body = "\(shortened)  ·  \(host)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
