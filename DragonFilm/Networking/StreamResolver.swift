import Foundation

/// Resolves protected/obfuscated embed player URLs into direct native HLS m3u8 streams.
enum StreamResolver {

    /// Asynchronously extracts a direct playback URL from an embed link.
    static func resolve(url: URL) async -> URL {
        let urlString = url.absoluteString

        // Direct m3u8 streams require no resolution
        if urlString.contains(".m3u8") {
            return url
        }

        // VSMov embed conversion
        if urlString.contains("streamvsmov.com/video/") {
            let m3u8 = urlString.replacingOccurrences(of: "/video/", with: "/stream/") + "/master.m3u8"
            if let directURL = URL(string: m3u8) {
                return directURL
            }
        }

        // NguonC / streamc.xyz embed resolution
        if urlString.contains("embed") || urlString.contains("streamc") || urlString.contains("nguonc") {
            if let directHLS = await resolveNguonCEmbed(url: url) {
                return directHLS
            }
        }

        return url
    }

    private static func resolveNguonCEmbed(url: URL) async -> URL? {
        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("https://phim.nguonc.com/", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 8

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let html = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        // Search for data-obf="..." attribute in #player div
        guard let match = html.range(of: "data-obf=[\"']([^\"']+)[\"']", options: .regularExpression) else {
            return nil
        }

        let fullMatch = String(html[match])
        guard let startQuote = fullMatch.firstIndex(of: "\"") ?? fullMatch.firstIndex(of: "'"),
              let endQuote = fullMatch.lastIndex(of: "\"") ?? fullMatch.lastIndex(of: "'"),
              startQuote < endQuote else {
            return nil
        }

        let b64 = String(fullMatch[fullMatch.index(after: startQuote)..<endQuote])
        guard let decodedData = Data(base64Encoded: b64),
              let json = try? JSONSerialization.jsonObject(with: decodedData) as? [String: Any],
              let sUb = json["sUb"] as? String else {
            return nil
        }

        guard let host = url.host, let scheme = url.scheme else { return nil }
        let directString = "\(scheme)://\(host)/\(sUb)"
        return URL(string: directString)
    }
}
