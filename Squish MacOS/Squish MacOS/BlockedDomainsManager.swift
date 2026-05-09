import Foundation

class BlockedDomainsManager {

    static let shared = BlockedDomainsManager()

    private let storageKey = "squish.blockedDomains"

    private let seedDomains: [String] = [
        // Version control / CI keys
        "github.com",
        "raw.githubusercontent.com",
        "gist.github.com",
        "gitlab.com",
        // Backend / infra
        "supabase.co",
        "supabase.com",
        "amazonaws.com",
        "cloudfront.net",
        "s3.amazonaws.com",
        // Hosting platforms
        "vercel.app",
        "railway.app",
        "render.com",
        "fly.io",
        "heroku.com",
        // Local
        "localhost",
        "127.0.0.1",
        "0.0.0.0"
    ]

    var domains: [String] {
        get {
            UserDefaults.standard.stringArray(forKey: storageKey) ?? seedDomains
        }
        set {
            UserDefaults.standard.set(newValue, forKey: storageKey)
        }
    }

    private init() {
        if UserDefaults.standard.object(forKey: storageKey) == nil {
            UserDefaults.standard.set(seedDomains, forKey: storageKey)
        }
    }

    func isBlocked(_ urlString: String) -> Bool {
        guard let host = URL(string: urlString)?.host?.lowercased() else { return false }
        return domains.contains { blocked in
            let b = blocked.lowercased()
            return host == b || host.hasSuffix(".\(b)")
        }
    }
}
