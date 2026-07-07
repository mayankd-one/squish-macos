import Foundation

/// Turns a URL into a friendly product/service name for display in the menu.
///
/// Resolution order:
///  1. Exact host match (subdomain-specific services, e.g. docs.google.com → Google Docs)
///  2. Google Workspace subdomains (any TLD)
///  3. Atlassian cloud (company.atlassian.net → Jira / Confluence, decided by path)
///  4. Registrable-domain match (linkedin.com → LinkedIn)
///  5. Fallback: capitalize the main domain label (mycompany.io → Mycompany)
enum SiteNameResolver {

    static func friendlyName(for urlString: String) -> String {
        let normalized = urlString.hasPrefix("http") ? urlString : "https://\(urlString)"
        guard let url = URL(string: normalized), var host = url.host?.lowercased() else {
            return fallbackName(fromRaw: urlString)
        }
        if host.hasPrefix("www.") { host.removeFirst(4) }
        let path = url.path.lowercased()

        // 1. Exact full-host matches.
        if let name = fullHostMap[host] { return name }

        // 2. Google Workspace subdomains, any TLD (google.com, google.co.in, …).
        if host == "google.com" || host.contains(".google.") || host.hasSuffix(".google") {
            return googleSubdomainName(host)
        }

        // 3. Atlassian cloud — Jira vs Confluence disambiguated by path.
        if host.hasSuffix("atlassian.net") {
            if path.hasPrefix("/wiki") { return "Confluence" }
            if path.hasPrefix("/browse/") || path.hasPrefix("/secure/")
                || path.contains("/jira") || path.contains("/software") {
                return "Jira"
            }
            return "Atlassian"
        }

        // 4. Registrable-domain matches.
        let domain = registrableDomain(host)
        if let name = domainMap[domain] { return name }

        // 5. Fallback.
        return fallbackName(fromHost: domain)
    }

    // MARK: - Google

    private static func googleSubdomainName(_ host: String) -> String {
        let sub = host.components(separatedBy: ".").first ?? ""
        switch sub {
        case "docs":      return "Google Docs"
        case "sheets":    return "Google Sheets"
        case "slides":    return "Google Slides"
        case "calendar":  return "Google Calendar"
        case "drive":     return "Google Drive"
        case "mail":      return "Gmail"
        case "meet":      return "Google Meet"
        case "photos":    return "Google Photos"
        case "chat":      return "Google Chat"
        case "forms":     return "Google Forms"
        case "keep":      return "Google Keep"
        case "maps":      return "Google Maps"
        case "translate": return "Google Translate"
        case "play":      return "Google Play"
        case "cloud", "console": return "Google Cloud"
        default:          return "Google"
        }
    }

    // MARK: - Lookup tables

    private static let fullHostMap: [String: String] = [
        // Google (explicit hosts; subdomain resolver covers the rest)
        "docs.google.com": "Google Docs",
        "sheets.google.com": "Google Sheets",
        "slides.google.com": "Google Slides",
        "calendar.google.com": "Google Calendar",
        "drive.google.com": "Google Drive",
        "mail.google.com": "Gmail",
        "meet.google.com": "Google Meet",
        // Microsoft
        "outlook.office.com": "Outlook",
        "outlook.office365.com": "Outlook",
        "outlook.live.com": "Outlook",
        "teams.microsoft.com": "Microsoft Teams",
        "teams.live.com": "Microsoft Teams",
        // Amazon / AWS
        "aws.amazon.com": "AWS",
        "console.aws.amazon.com": "AWS",
        // Media / misc subdomains
        "web.whatsapp.com": "WhatsApp",
        "music.youtube.com": "YouTube Music",
        "studio.youtube.com": "YouTube Studio",
        "open.spotify.com": "Spotify",
        "app.slack.com": "Slack"
    ]

    private static let domainMap: [String: String] = [
        "google.com": "Google",
        "youtube.com": "YouTube",
        "youtu.be": "YouTube",
        "gmail.com": "Gmail",
        "linkedin.com": "LinkedIn",
        "github.com": "GitHub",
        "gitlab.com": "GitLab",
        "bitbucket.org": "Bitbucket",
        "figma.com": "Figma",
        "notion.so": "Notion",
        "slack.com": "Slack",
        "zoom.us": "Zoom",
        "trello.com": "Trello",
        "asana.com": "Asana",
        "atlassian.com": "Atlassian",
        "jira.com": "Jira",
        "confluence.com": "Confluence",
        "twitter.com": "X (Twitter)",
        "x.com": "X (Twitter)",
        "facebook.com": "Facebook",
        "instagram.com": "Instagram",
        "reddit.com": "Reddit",
        "stackoverflow.com": "Stack Overflow",
        "medium.com": "Medium",
        "substack.com": "Substack",
        "dropbox.com": "Dropbox",
        "amazon.com": "Amazon",
        "netflix.com": "Netflix",
        "spotify.com": "Spotify",
        "apple.com": "Apple",
        "icloud.com": "iCloud",
        "microsoft.com": "Microsoft",
        "office.com": "Microsoft 365",
        "office365.com": "Microsoft 365",
        "live.com": "Microsoft",
        "outlook.com": "Outlook",
        "canva.com": "Canva",
        "miro.com": "Miro",
        "loom.com": "Loom",
        "vercel.com": "Vercel",
        "vercel.app": "Vercel",
        "netlify.app": "Netlify",
        "netlify.com": "Netlify",
        "supabase.com": "Supabase",
        "supabase.co": "Supabase",
        "wikipedia.org": "Wikipedia",
        "chatgpt.com": "ChatGPT",
        "openai.com": "OpenAI",
        "claude.ai": "Claude",
        "anthropic.com": "Anthropic",
        "pinterest.com": "Pinterest",
        "whatsapp.com": "WhatsApp",
        "telegram.org": "Telegram",
        "discord.com": "Discord",
        "discord.gg": "Discord",
        "tiktok.com": "TikTok",
        "airtable.com": "Airtable",
        "clickup.com": "ClickUp",
        "monday.com": "Monday.com",
        "salesforce.com": "Salesforce",
        "hubspot.com": "HubSpot",
        "stripe.com": "Stripe",
        "paypal.com": "PayPal",
        "shopify.com": "Shopify",
        "wordpress.com": "WordPress",
        "behance.net": "Behance",
        "dribbble.com": "Dribbble",
        "producthunt.com": "Product Hunt",
        "quora.com": "Quora",
        "twitch.tv": "Twitch",
        "vimeo.com": "Vimeo",
        "soundcloud.com": "SoundCloud"
    ]

    // MARK: - Registrable domain

    /// Public suffixes that use two labels (so the registrable domain is three labels).
    private static let twoLevelSuffixes: Set<String> = [
        "co.uk", "co.in", "co.jp", "co.kr", "co.nz", "co.za",
        "com.au", "com.br", "com.cn", "com.mx", "com.sg", "com.tr",
        "org.uk", "net.au", "gov.uk", "ac.uk", "ac.in"
    ]

    private static func registrableDomain(_ host: String) -> String {
        let parts = host.components(separatedBy: ".")
        guard parts.count > 2 else { return host }
        let lastTwo = parts.suffix(2).joined(separator: ".")
        if twoLevelSuffixes.contains(lastTwo) {
            return parts.suffix(3).joined(separator: ".")
        }
        return lastTwo
    }

    // MARK: - Fallback

    private static func fallbackName(fromHost domain: String) -> String {
        let label = domain.components(separatedBy: ".").first ?? domain
        guard let first = label.first else { return domain }
        return first.uppercased() + label.dropFirst()
    }

    private static func fallbackName(fromRaw raw: String) -> String {
        var s = raw.lowercased()
        for prefix in ["https://", "http://", "www."] {
            s = s.replacingOccurrences(of: prefix, with: "")
        }
        let host = s.components(separatedBy: "/").first ?? s
        return fallbackName(fromHost: registrableDomain(host))
    }
}
