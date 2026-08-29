import Foundation

struct Movie: Codable, Identifiable, Hashable {
    let slug: String
    let name: String
    let originName: String
    let thumbURL: String
    let posterURL: String
    let year: LenientScalar
    let type: String
    let episodeCurrent: String
    let quality: String?
    let lang: String?
    let category: [Genre]
    let country: [Genre]
    let actor: [PersonRef]?
    let director: [PersonRef]?
    let tmdb: TMDBInfo?
    let imdb: TMDBInfo?

    let server: String?
    let sources: [String]?
    let serverSlugs: [String: String]?
    let sourceThumbURL: String?
    let sourcePosterURL: String?

    var id: String { slug }
    var bestBanner: String {
        if let source = sourceThumbURL, !source.isEmpty { return source }
        if activeServer == .ophim || activeServer == .nguonc {
            if !posterURL.isEmpty { return posterURL }
            if let backdrop = tmdb?.backdropURL, !backdrop.isEmpty { return backdrop }
            if let thumb = tmdb?.thumbURL, !thumb.isEmpty { return thumb }
            return bestPoster
        } else {
            if let backdrop = tmdb?.backdropURL, !backdrop.isEmpty { return backdrop }
            if let thumb = tmdb?.thumbURL, !thumb.isEmpty { return thumb }
            if !thumbURL.isEmpty { return thumbURL }
            return bestPoster
        }
    }
    var bestPoster: String {
        if let source = sourcePosterURL, !source.isEmpty { return source }
        if activeServer == .kkphim {
            if !posterURL.isEmpty { return posterURL }
            if let poster = tmdb?.posterURL, !poster.isEmpty { return poster }
            if !thumbURL.isEmpty { return thumbURL }
            return ""
        } else {
            // For OPhim, NguonC, VSMov: thumbURL is the portrait poster!
            if !thumbURL.isEmpty { return thumbURL }
            if let poster = tmdb?.posterURL, !poster.isEmpty { return poster }
            if !posterURL.isEmpty { return posterURL }
            return ""
        }
    }
    var bestThumb: String { bestBanner }
    var activeServer: SourceServer { SourceServer(rawValue: server ?? "") ?? .kkphim }
    var availableSources: [String] { sources ?? [] }
    var slugsByServer: [String: String] { serverSlugs ?? [:] }
    var yearString: String { year.stringVal }
    var isSeries: Bool { type == "series" || type == "hoathinh" || type == "tvshows" }
    var categoryString: String {
        let names = category.map(\.name)
        return names.isEmpty ? "Phim Điện Ảnh" : names.prefix(3).joined(separator: ", ")
    }
    var formattedScore: (label: String, score: String) {
        if let imdb, imdb.scoreString != "N/A" {
            return ("IMDb", imdb.scoreString)
        }
        if let tmdb, tmdb.scoreString != "N/A" {
            return ("TMDB", tmdb.scoreString)
        }
        return ("IMDb", "9.6")
    }
    var cleanQuality: String {
        if let q = quality, !q.isEmpty { return q.uppercased() }
        return "HD"
    }
    var episodeBadge: String {
        if !episodeCurrent.isEmpty { return episodeCurrent }
        return isSeries ? "Tập mới" : "Bản đẹp"
    }

    enum CodingKeys: String, CodingKey {
        case slug, name, type, quality, lang, category, country, actor, director, tmdb, imdb, year
        case originName = "origin_name"
        case thumbURL = "thumb_url"
        case posterURL = "poster_url"
        case episodeCurrent = "episode_current"
        case server = "_server"
        case sources = "_sources"
        case serverSlugs = "_serverSlugs"
        case sourceThumbURL = "_source_thumb_url"
        case sourcePosterURL = "_source_poster_url"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        slug = try c.decode(String.self, forKey: .slug)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? slug
        originName = try c.decodeIfPresent(String.self, forKey: .originName) ?? ""
        thumbURL = try c.decodeIfPresent(String.self, forKey: .thumbURL) ?? ""
        posterURL = try c.decodeIfPresent(String.self, forKey: .posterURL) ?? ""
        year = try c.decodeIfPresent(LenientScalar.self, forKey: .year) ?? .string("")
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? "single"
        episodeCurrent = try c.decodeIfPresent(String.self, forKey: .episodeCurrent) ?? ""
        quality = try c.decodeIfPresent(String.self, forKey: .quality)
        lang = try c.decodeIfPresent(String.self, forKey: .lang)
        category = try c.decodeIfPresent([Genre].self, forKey: .category) ?? []
        country = try c.decodeIfPresent([Genre].self, forKey: .country) ?? []
        actor = try c.decodeIfPresent([PersonRef].self, forKey: .actor)
        director = try c.decodeIfPresent([PersonRef].self, forKey: .director)
        tmdb = try c.decodeIfPresent(TMDBInfo.self, forKey: .tmdb)
        imdb = try c.decodeIfPresent(TMDBInfo.self, forKey: .imdb)
        server = try c.decodeIfPresent(String.self, forKey: .server)
        sources = try c.decodeIfPresent([String].self, forKey: .sources)
        serverSlugs = try c.decodeIfPresent([String: String].self, forKey: .serverSlugs)
        sourceThumbURL = try c.decodeIfPresent(String.self, forKey: .sourceThumbURL)
        sourcePosterURL = try c.decodeIfPresent(String.self, forKey: .sourcePosterURL)
    }

    init(slug: String, name: String, originName: String = "", thumbURL: String = "",
         posterURL: String = "", year: LenientScalar = .string(""), type: String = "single",
         episodeCurrent: String = "", quality: String? = nil, lang: String? = nil,
         category: [Genre] = [], country: [Genre] = [], actor: [PersonRef]? = nil,
         director: [PersonRef]? = nil, tmdb: TMDBInfo? = nil, imdb: TMDBInfo? = nil,
         server: String? = nil, sources: [String]? = nil, serverSlugs: [String: String]? = nil,
         sourceThumbURL: String? = nil, sourcePosterURL: String? = nil) {
        self.slug = slug; self.name = name; self.originName = originName
        self.thumbURL = thumbURL; self.posterURL = posterURL; self.year = year
        self.type = type; self.episodeCurrent = episodeCurrent
        self.quality = quality; self.lang = lang
        self.category = category; self.country = country
        self.actor = actor; self.director = director
        self.tmdb = tmdb; self.imdb = imdb
        self.server = server; self.sources = sources; self.serverSlugs = serverSlugs
        self.sourceThumbURL = sourceThumbURL; self.sourcePosterURL = sourcePosterURL
    }

    static func == (lhs: Movie, rhs: Movie) -> Bool {
        lhs.slug == rhs.slug && lhs.server == rhs.server
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(slug)
        hasher.combine(server)
    }

    /// Matches `movieCommentKey` in the web client so comments are shared
    /// between web and app for the same title.
    var commentKey: String {
        let source = originName.isEmpty ? name : originName
        let normalised = source
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        return "\(normalised):\(yearString)"
    }
}

struct Genre: Codable, Identifiable, Hashable {
    let name: String
    let slug: String
    var id: String { slug }
}

struct TMDBInfo: Codable, Hashable {
    let id: LenientScalar?
    let type: String?
    let season: LenientScalar?
    let voteAverage: LenientScalar?
    let voteCount: LenientScalar?
    let posterURL: String?
    let backdropURL: String?
    let thumbURL: String?

    enum CodingKeys: String, CodingKey {
        case id, type, season
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case posterURL = "poster_url"
        case backdropURL = "backdrop_url"
        case thumbURL = "thumb_url"
    }

    var scoreString: String {
        guard let voteAverage, !voteAverage.isEmpty else { return "N/A" }
        let d = voteAverage.doubleVal
        guard d > 0 else { return "N/A" }
        return String(format: "%.1f", d)
    }
}

struct Episode: Codable, Identifiable {
    let id: String
    let name: String
    let slug: String
    let filename: String?
    let linkM3U8: String?
    let linkEmbed: String?

    init(id: String, name: String, slug: String, filename: String? = nil,
         linkM3U8: String? = nil, linkEmbed: String? = nil) {
        self.id = id; self.name = name; self.slug = slug
        self.filename = filename; self.linkM3U8 = linkM3U8; self.linkEmbed = linkEmbed
    }

    enum CodingKeys: String, CodingKey {
        case id, name, slug, filename
        case linkM3U8 = "link_m3u8"
        case linkEmbed = "link_embed"
    }
}

struct EpisodeServer: Codable, Identifiable {
    let serverName: String
    let items: [Episode]

    var id: String { serverName }

    enum CodingKeys: String, CodingKey {
        case serverName = "server_name"
        case items
    }
}

struct User: Codable, Identifiable {
    let id: String
    let username: String
    let email: String
    let phone: String
    let avatarURL: String
    let role: String
    let isAdmin: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, username, email, phone, role
        case avatarURL = "avatar_url"
        case isAdmin = "is_admin"
        case createdAt = "created_at"
    }
}

struct Comment: Codable, Identifiable {
    let id: String
    let movieKey: String
    let body: String
    let createdAt: String
    let user: CommentUser

    enum CodingKeys: String, CodingKey {
        case id, body
        case movieKey = "movie_key"
        case createdAt = "created_at"
        case user
    }
}

struct CommentUser: Codable {
    let id: String
    let username: String
    let avatarURL: String?
    let role: String
    let isAdmin: Bool

    enum CodingKeys: String, CodingKey {
        case id, username, role
        case avatarURL = "avatar_url"
        case isAdmin = "is_admin"
    }
}

struct HomeRow: Codable, Identifiable {
    let key: String
    let title: String
    let items: [Movie]
    var id: String { key }
}

struct HomeResponse: Codable {
    let rows: [HomeRow]
}
