import Foundation

enum URLShortener {

    nonisolated static func shorten(_ urlString: String) async -> String? {
        guard
            let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let apiURL = URL(string: "https://tinyurl.com/api-create.php?url=\(encoded)")
        else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: apiURL)
            guard
                let http = response as? HTTPURLResponse,
                http.statusCode == 200,
                let result = String(data: data, encoding: .utf8),
                result.hasPrefix("https://tinyurl.com") || result.hasPrefix("http://tinyurl.com")
            else { return nil }
            return result.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
}
