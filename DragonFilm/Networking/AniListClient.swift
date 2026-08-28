import Foundation

/// Direct GraphQL client for AniList (Worker does not proxy this endpoint).
enum AniListClient {
    private static let url = URL(string: "https://graphql.anilist.co")!
    private static let decoder = JSONDecoder()

    /// A stalled QUIC handshake does not trip `timeoutIntervalForRequest` (that
    /// only measures gaps between packets), so a hard resource deadline is set to
    /// make a hung connection fail fast instead of hanging for ~180s.
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 15
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    private static let seasonLabels: [String: String] = [
        "WINTER": "Mùa Đông", "SPRING": "Mùa Xuân",
        "SUMMER": "Mùa Hè", "FALL": "Mùa Thu"
    ]

    // MARK: - Public API

    static func weeklyTrending(limit: Int = 12) async throws -> [AniListNormalized] {
        let query = """
        query ($perPage: Int) {
          Page(page: 1, perPage: $perPage) {
            media(type: ANIME, sort: TRENDING_DESC) {
              id title { romaji english native }
              synonyms format status episodes duration
              seasonYear startDate { year }
              averageScore meanScore popularity genres
              coverImage { large extraLarge }
              bannerImage siteUrl
              studios(isMain: true) { nodes { name } }
            }
          }
        }
        """
        return try await fetch(query: query, variables: ["perPage": limit])
    }

    static func seasonRanking(limit: Int = 12) async throws -> (season: String, label: String, items: [AniListNormalized]) {
        let info = currentSeason()
        let query = """
        query ($perPage: Int, $season: MediaSeason, $seasonYear: Int) {
          Page(page: 1, perPage: $perPage) {
            media(type: ANIME, season: $season, seasonYear: $seasonYear, sort: TRENDING_DESC) {
              id title { romaji english native }
              synonyms format status episodes duration
              seasonYear startDate { year }
              averageScore meanScore popularity genres
              coverImage { large extraLarge }
              bannerImage siteUrl
              studios(isMain: true) { nodes { name } }
            }
          }
        }
        """
        let items = try await fetch(query: query, variables: [
            "perPage": limit, "season": info.key, "seasonYear": info.year
        ])
        return (info.key, info.label, items)
    }

    // MARK: - Internals

    private static func fetch(query: String, variables: [String: Any]) async throws -> [AniListNormalized] {
        var req = URLRequest(url: url, timeoutInterval: 12)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("DragonFilm-iOS", forHTTPHeaderField: "Referer")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "query": query, "variables": variables
        ])
        let (data, _) = try await session.data(for: req)
        let envelope = try decoder.decode(AniListEnvelope.self, from: data)
        return (envelope.data?.page.media ?? []).map { AniListNormalized(media: $0) }
    }

    private static func currentSeason(date: Date = .now) -> (key: String, label: String, year: Int) {
        let cal = Calendar.current
        let month = cal.component(.month, from: date)
        let year = cal.component(.year, from: date)
        let key: String
        if month <= 3 { key = "WINTER" }
        else if month <= 6 { key = "SPRING" }
        else if month <= 9 { key = "SUMMER" }
        else { key = "FALL" }
        return (key, seasonLabels[key] ?? key, year)
    }
}
