import Foundation

struct NetflixItem: Codable, Identifiable {
    let rank: Int
    let title: String
    let type: String
    let poster: String?
    let posterURL: String?
    let logoURL: String?
    let tmdb: NetflixTMDB?
    var id: Int { rank }

    enum CodingKeys: String, CodingKey {
        case rank, title, type, poster, tmdb
        case posterURL = "poster_url"
        case logoURL = "logo_url"
    }
}

struct NetflixTMDB: Codable {
    let id: LenientScalar?
    let voteAverage: Double?
    let posterURL: String?
    let backdropURL: String?
    let thumbURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case voteAverage = "vote_average"
        case posterURL = "poster_url"
        case backdropURL = "backdrop_url"
        case thumbURL = "thumb_url"
    }
}

struct NetflixResponse: Codable {
    let source: String?
    let items: [NetflixItem]
    let updatedAt: String?
}

struct TMDBWeeklyItem: Codable, Identifiable {
    let rank: Int
    let tmdbID: LenientScalar?
    let title: String
    let originalTitle: String?
    let overview: String?
    let posterURL: String?
    let backdropURL: String?
    let voteAverage: Double?
    let popularity: Double?
    var id: Int { rank }

    enum CodingKeys: String, CodingKey {
        case rank, title, overview, popularity
        case tmdbID = "tmdb_id"
        case originalTitle = "original_title"
        case posterURL = "poster_url"
        case backdropURL = "backdrop_url"
        case voteAverage = "vote_average"
    }
}

struct TMDBWeeklyResponse: Codable {
    let ok: Bool
    let country: String
    let label: String?
    let items: [TMDBWeeklyItem]
}

struct AniListMedia: Decodable, Identifiable {
    let id: Int
    let title: AniListTitle
    let synonyms: [String]?
    let description: String?
    let format: String?
    let status: String?
    let episodes: Int?
    let duration: Int?
    let seasonYear: Int?
    let startDate: AniDate?
    let averageScore: Int?
    let meanScore: Int?
    let popularity: Int?
    let genres: [String]?
    let coverImage: CoverImage?
    let bannerImage: String?
    let siteUrl: String?

    struct AniListTitle: Decodable {
        let romaji: String?
        let english: String?
        let native: String?
    }
    struct AniDate: Decodable {
        let year: Int?
    }
    struct CoverImage: Decodable {
        let large: String?
        let extraLarge: String?
    }
}

struct AniListPage: Decodable {
    let page: Page
    struct Page: Decodable {
        let media: [AniListMedia]
    }
    enum CodingKeys: String, CodingKey { case page = "Page" }
}

/// AniList is queried directly (the Worker does not proxy GraphQL), so the
/// `{data: ...}` GraphQL envelope has to be unwrapped here.
struct AniListEnvelope: Decodable {
    let data: AniListPage?
}

struct AniListNormalized: Identifiable {
    let id: Int
    let titleEN: String
    let titleRomaji: String
    let titleNative: String
    let coverURL: String
    let score: Int
    let popularity: Int
    let year: Int
    let format: String
    let genres: [String]

    init(media: AniListMedia) {
        id = media.id
        titleEN = media.title.english ?? ""
        titleRomaji = media.title.romaji ?? ""
        titleNative = media.title.native ?? ""
        coverURL = media.coverImage?.extraLarge ?? media.coverImage?.large ?? ""
        score = media.averageScore ?? 0
        popularity = media.popularity ?? 0
        year = media.seasonYear ?? media.startDate?.year ?? 0
        format = media.format ?? ""
        genres = media.genres ?? []
    }

    var title: String { titleEN.isEmpty ? titleRomaji : titleEN }
    var altTitle: String {
        if !titleEN.isEmpty && !titleRomaji.isEmpty { return titleRomaji }
        return titleNative
    }
}

struct ScheduleDay: Identifiable {
    let date: Date
    var id: String { ISO8601DateFormatter().string(from: date) }
    var display: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "vi_VN")
        f.dateFormat = "EEE dd/MM"
        return f.string(from: date)
    }
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}
