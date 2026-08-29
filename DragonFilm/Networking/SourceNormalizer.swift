import Foundation

struct SourceMovie: Codable {
    let slug: String
    let name: String
    let originName: String
    let thumbURL: String
    let posterURL: String
    let year: LenientScalar?
    let type: String?
    let episodeCurrent: String?
    let quality: String?
    let lang: String?
    let category: [Genre]?
    let country: [Genre]?

    enum CodingKeys: String, CodingKey {
        case slug, name
        case originName = "origin_name"
        case thumbURL = "thumb_url"
        case posterURL = "poster_url"
        case year, type
        case episodeCurrent = "episode_current"
        case quality, lang, category, country
    }
}

struct SourceDetail: Codable {
    let movie: SourceDetailMovie?
    let episodes: [[String: AnyCodable]]?
}

struct SourceDetailMovie: Codable {
    let slug: String
    let name: String
    let originName: String
    let thumbURL: String
    let posterURL: String
    let content: String?
    let year: LenientScalar?
    let type: String?
    let status: String?
    let episodeCurrent: String?
    let episodeTotal: String?
    let quality: String?
    let lang: String?
    let category: [Genre]?
    let country: [Genre]?
    let actor: [PersonRef]?
    let director: [PersonRef]?

    enum CodingKeys: String, CodingKey {
        case slug, name, content, year, type, status, quality, lang, category, country, actor, director
        case originName = "origin_name"
        case thumbURL = "thumb_url"
        case posterURL = "poster_url"
        case episodeCurrent = "episode_current"
        case episodeTotal = "episode_total"
    }
}

struct AnyCodable: Codable {
    let value: Any
    init(_ value: Any) { self.value = value }
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let i = try? c.decode(Int.self) { value = i }
        else if let d = try? c.decode(Double.self) { value = d }
        else if let s = try? c.decode(String.self) { value = s }
        else if let b = try? c.decode(Bool.self) { value = b }
        else if let arr = try? c.decode([AnyCodable].self) { value = arr.map(\.value) }
        else if let obj = try? c.decode([String: AnyCodable].self) { value = obj.mapValues(\.value) }
        else { value = NSNull() }
    }
    func encode(to encoder: Encoder) throws {}
}

enum SourceServer: String, CaseIterable, Identifiable {
    case kkphim, nguonc, vsmov
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .kkphim: return "SV 1"
        case .nguonc: return "SV 2"
        case .vsmov:  return "SV 3"
        }
    }
}

struct SourceNormalizer {

    static func searchPath(keyword: String, page: Int) -> String {
        let kw = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
        return "/v1/api/tim-kiem?keyword=\(kw)&page=\(page)"
    }

    static func latestPath(page: Int) -> String {
        "/danh-sach/phim-moi-cap-nhat?page=\(page)"
    }

    static func detailPath(slug: String) -> String {
        "/phim/\(slug)"
    }

    static func genrePath(slug: String, page: Int) -> String {
        "/v1/api/the-loai/\(slug)?page=\(page)"
    }

    static func countryPath(slug: String, page: Int) -> String {
        "/v1/api/quoc-gia/\(slug)?page=\(page)"
    }

    static func categoryPath(type: String, page: Int) -> String {
        "/v1/api/danh-sach/\(type)?page=\(page)"
    }

    static func upstreamPath(for server: SourceServer, operation: String, slug: String? = nil, keyword: String? = nil, page: Int = 1) -> String {
        let kw = (keyword ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword ?? ""
        switch server {
        case .kkphim:
            switch operation {
            case "latest": return "/danh-sach/phim-moi-cap-nhat?page=\(page)"
            case "search": return "/v1/api/tim-kiem?keyword=\(kw)&page=\(page)"
            case "detail": return "/phim/\(slug ?? "")"
            case "genre":  return "/v1/api/the-loai/\(slug ?? "")?page=\(page)"
            case "country": return "/v1/api/quoc-gia/\(slug ?? "")?page=\(page)"
            default: return ""
            }
        case .nguonc:
            switch operation {
            case "latest": return "/api/films/phim-moi-cap-nhat?page=\(page)"
            case "search": return "/api/films/search?keyword=\(kw)&page=\(page)"
            case "detail": return "/api/film/\(slug ?? "")"
            case "genre":  return "/api/films/danh-sach/\(slug ?? "")?page=\(page)"
            case "country": return "/api/films/quoc-gia/\(slug ?? "")?page=\(page)"
            default: return ""
            }
        case .vsmov:
            switch operation {
            case "latest": return "/api/danh-sach/phim-moi-cap-nhat?page=\(page)"
            case "search": return "/api/tim-kiem?keyword=\(kw)&page=\(page)"
            case "detail": return "/api/phim/\(slug ?? "")"
            case "genre":  return "/api/the-loai/\(slug ?? "")?page=\(page)"
            case "country": return "/api/quoc-gia/\(slug ?? "")?page=\(page)"
            default: return ""
            }
        }
    }
}
