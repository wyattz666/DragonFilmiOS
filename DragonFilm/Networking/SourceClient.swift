import Foundation

/// Fetches the movie catalog through the Worker's `/api/source` proxy.
///
/// The four upstreams return incompatible JSON, so every response goes through
/// `extractItems`/`extractEpisodes` rather than a single Codable shape. This
/// mirrors `_extractMovieItems` and `_parseEpisodes` in the web client.
struct SourceClient {

    static func list(server: SourceServer, operation: String, slug: String? = nil,
                     keyword: String? = nil, page: Int = 1) async throws -> (movies: [Movie], totalPages: Int) {
        let path = SourceNormalizer.upstreamPath(for: server, operation: operation,
                                                 slug: slug, keyword: keyword, page: page)
        let data = try await APIClient.shared.rawData("/api/source",
                                                     query: ["server": server.rawValue, "path": path])
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ([], 1)
        }
        let items = extractItems(root)
        let movies = items.compactMap { movie(from: $0, server: server) }
        return (movies, extractTotalPages(root))
    }

    static func detail(server: SourceServer, slug: String) async throws -> (movie: Movie, episodes: [EpisodeServer], description: String) {
        let path = SourceNormalizer.upstreamPath(for: server, operation: "detail", slug: slug)
        let data = try await APIClient.shared.rawData("/api/source",
                                                     query: ["server": server.rawValue, "path": path])
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.invalidResponse
        }

        let movieDict = unwrapDetail(root)
        guard let movieDict, let parsed = movie(from: movieDict, server: server) else {
            throw APIError.invalidResponse
        }

        let episodeRaw = (root["episodes"] as? [[String: Any]])
            ?? ((root["data"] as? [String: Any])?["episodes"] as? [[String: Any]])
            ?? (movieDict["episodes"] as? [[String: Any]])
            ?? []

        let episodes = server == .nguonc
            ? parseEpisodesNguonC(episodeRaw)
            : parseEpisodes(episodeRaw)

        let description = string(movieDict["content"]) ?? string(movieDict["description"]) ?? ""
        return (parsed, episodes, stripHTML(description))
    }

    // MARK: - Extraction

    /// The upstreams disagree on where the array lives; probe the known keys in
    /// the same order as the web client so results stay consistent.
    static func extractItems(_ root: [String: Any]) -> [[String: Any]] {
        if let items = root["items"] as? [[String: Any]] { return items }
        if let data = root["data"] as? [String: Any] {
            if let items = data["items"] as? [[String: Any]] { return items }
            if let movies = data["movies"] as? [[String: Any]] { return movies }
        }
        if let data = root["data"] as? [[String: Any]] { return data }
        if let movies = root["movies"] as? [[String: Any]] { return movies }
        if let movie = root["movie"] as? [String: Any] { return [movie] }
        if let film = root["film"] as? [String: Any] { return [film] }
        return []
    }

    static func extractTotalPages(_ root: [String: Any]) -> Int {
        let candidates: [Any?] = [
            (root["paginate"] as? [String: Any])?["total_page"],
            (root["paginate"] as? [String: Any])?["last_page"],
            (root["pagination"] as? [String: Any])?["totalPages"],
            (root["pagination"] as? [String: Any])?["total_page"],
            (root["pagination"] as? [String: Any])?["last_page"],
            ((root["data"] as? [String: Any])?["params"] as? [String: Any])
                .flatMap { ($0["pagination"] as? [String: Any])?["totalPages"] },
            root["total_pages"],
            root["totalPages"]
        ]
        for candidate in candidates {
            if let n = int(candidate), n > 0 { return n }
        }
        return 1
    }

    private static func unwrapDetail(_ root: [String: Any]) -> [String: Any]? {
        if let movie = root["movie"] as? [String: Any] { return movie }
        if let data = root["data"] as? [String: Any] {
            if let item = data["item"] as? [String: Any] { return item }
            if let movie = data["movie"] as? [String: Any] { return movie }
            return data
        }
        return root["slug"] != nil || root["name"] != nil ? root : nil
    }

    // MARK: - Episodes

    static func parseEpisodes(_ raw: [[String: Any]]) -> [EpisodeServer] {
        raw.compactMap { group in
            let serverName = string(group["server_name"]) ?? "Server"
            let items = (group["server_data"] as? [[String: Any]])
                ?? (group["items"] as? [[String: Any]])
                ?? []
            let episodes = items.enumerated().map { idx, ep in
                let rawM3U8 = string(ep["link_m3u8"]) ?? string(ep["m3u8"])
                let rawEmbed = string(ep["link_embed"]) ?? string(ep["embed"])

                var m3u8 = rawM3U8
                if (m3u8 == nil || m3u8?.isEmpty == true), let embed = rawEmbed {
                    if embed.contains("streamvsmov.com/video/") {
                        m3u8 = embed.replacingOccurrences(of: "/video/", with: "/stream/") + "/master.m3u8"
                    }
                }

                return Episode(
                    id: string(ep["slug"]) ?? "ep-\(idx)",
                    name: string(ep["name"]) ?? "Tập \(idx + 1)",
                    slug: string(ep["slug"]) ?? "",
                    filename: string(ep["filename"]),
                    linkM3U8: m3u8,
                    linkEmbed: rawEmbed
                )
            }
            return episodes.isEmpty ? nil : EpisodeServer(serverName: serverName, items: episodes)
        }
    }

    /// NguonC nests episodes under `items` and names the stream keys `m3u8`/`embed`.
    static func parseEpisodesNguonC(_ raw: [[String: Any]]) -> [EpisodeServer] {
        raw.compactMap { group in
            let serverName = string(group["server_name"]) ?? "Server"
            let items = (group["items"] as? [[String: Any]]) ?? []
            let episodes = items.enumerated().map { idx, ep in
                Episode(
                    id: string(ep["slug"]) ?? "ep-\(idx)",
                    name: string(ep["name"]) ?? "Tập \(idx + 1)",
                    slug: string(ep["slug"]) ?? "",
                    filename: string(ep["filename"]),
                    linkM3U8: string(ep["m3u8"]) ?? string(ep["link_m3u8"]),
                    linkEmbed: string(ep["embed"]) ?? string(ep["link_embed"])
                )
            }
            return episodes.isEmpty ? nil : EpisodeServer(serverName: serverName, items: episodes)
        }
    }

    // MARK: - Movie mapping

    static func movie(from dict: [String: Any], server: SourceServer) -> Movie? {
        guard let slug = string(dict["slug"]), !slug.isEmpty else { return nil }
        let name = string(dict["name"]) ?? slug
        let tmdb = parseTMDB(dict["tmdb"])
        let imdb = parseIMDB(dict["imdb"])
        let actor = parsePersons(dict["actor"] ?? dict["actors"])
        let director = parsePersons(dict["director"] ?? dict["directors"])

        return Movie(
            slug: slug,
            name: name,
            originName: string(dict["origin_name"]) ?? string(dict["original_name"]) ?? "",
            thumbURL: absoluteImage(string(dict["thumb_url"]), server: server),
            posterURL: absoluteImage(string(dict["poster_url"]), server: server),
            year: LenientScalar.from(dict["year"]),
            type: string(dict["type"]) ?? "single",
            episodeCurrent: string(dict["episode_current"]) ?? "",
            quality: string(dict["quality"]),
            lang: string(dict["lang"]),
            category: genres(dict["category"]),
            country: genres(dict["country"]),
            actor: actor,
            director: director,
            tmdb: tmdb,
            imdb: imdb,
            server: server.rawValue,
            sources: [server.rawValue],
            serverSlugs: [server.rawValue: slug],
            sourceThumbURL: nil,
            sourcePosterURL: nil
        )
    }

    private static func parseTMDB(_ value: Any?) -> TMDBInfo? {
        guard let dict = value as? [String: Any] else { return nil }
        return TMDBInfo(
            id: LenientScalar.fromOptional(dict["id"]),
            type: string(dict["type"]),
            season: LenientScalar.fromOptional(dict["season"]),
            voteAverage: LenientScalar.fromOptional(dict["vote_average"] ?? dict["voteAverage"]),
            voteCount: LenientScalar.fromOptional(dict["vote_count"] ?? dict["voteCount"]),
            posterURL: string(dict["poster_url"] ?? dict["poster_path"]),
            backdropURL: string(dict["backdrop_url"] ?? dict["backdrop_path"]),
            thumbURL: string(dict["thumb_url"])
        )
    }

    private static func parseIMDB(_ value: Any?) -> TMDBInfo? {
        guard let dict = value as? [String: Any] else { return nil }
        return TMDBInfo(
            id: LenientScalar.fromOptional(dict["id"]),
            type: string(dict["type"]),
            season: nil,
            voteAverage: LenientScalar.fromOptional(dict["vote_average"] ?? dict["voteAverage"] ?? dict["rate"]),
            voteCount: LenientScalar.fromOptional(dict["vote_count"] ?? dict["voteCount"] ?? dict["votes"]),
            posterURL: nil,
            backdropURL: nil,
            thumbURL: nil
        )
    }

    private static func parsePersons(_ value: Any?) -> [PersonRef]? {
        guard let value else { return nil }
        if let strArr = value as? [String] {
            let filtered = strArr.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            return filtered.isEmpty ? nil : filtered.map { .plain($0) }
        }
        if let dictArr = value as? [[String: Any]] {
            let refs = dictArr.compactMap { d -> PersonRef? in
                guard let name = string(d["name"]) else { return nil }
                let character = string(d["character"]) ?? ""
                let profile = string(d["profile_url"]) ?? string(d["profile_path"]) ?? ""
                if !character.isEmpty || !profile.isEmpty {
                    return .detailed(name: name, character: character, profileURL: profile)
                }
                return .plain(name)
            }
            return refs.isEmpty ? nil : refs
        }
        if let str = value as? String {
            let items = str.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            return items.isEmpty ? nil : items.map { .plain($0) }
        }
        return nil
    }

    /// Upstreams return bare filenames for some records; prefix the per-server
    /// image host so the proxy receives an absolute allowlisted URL.
    private static func absoluteImage(_ value: String?, server: SourceServer) -> String {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return "" }
        if value.hasPrefix("http://") || value.hasPrefix("https://") { return value }
        if value.hasPrefix("//") { return "https:" + value }

        let cleaned = value.hasPrefix("/") ? String(value.dropFirst()) : value
        switch server {
        case .kkphim:
            return "https://phimimg.com/\(cleaned)"
        case .nguonc:
            return "https://phim.nguonc.com/\(cleaned)"
        case .vsmov:
            return "https://vsmov.com/\(cleaned)"
        }
    }

    private static func genres(_ value: Any?) -> [Genre] {
        guard let arr = value as? [[String: Any]] else { return [] }
        return arr.compactMap { item in
            guard let name = string(item["name"]) else { return nil }
            return Genre(name: name, slug: string(item["slug"]) ?? name.lowercased())
        }
    }

    // MARK: - Scalar helpers

    private static func string(_ value: Any?) -> String? {
        if let s = value as? String { return s.isEmpty ? nil : s }
        if let n = value as? NSNumber { return n.stringValue }
        return nil
    }

    private static func int(_ value: Any?) -> Int? {
        if let n = value as? Int { return n }
        if let n = value as? NSNumber { return n.intValue }
        if let s = value as? String { return Int(s) }
        return nil
    }

    private static func stripHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
