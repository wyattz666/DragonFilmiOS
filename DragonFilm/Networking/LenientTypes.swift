import Foundation

/// `year`, `tmdb.id`, `tmdb.season` and `imdb.id` arrive as Int, String or ""
/// depending on which upstream supplied the record.
enum LenientScalar: Codable, Hashable {
    case int(Int)
    case double(Double)
    case string(String)

    var intVal: Int {
        switch self {
        case .int(let v): return v
        case .double(let v): return Int(v)
        case .string(let s): return Int(s) ?? 0
        }
    }

    var stringVal: String {
        switch self {
        case .int(let v): return String(v)
        case .double(let v): return String(format: "%g", v)
        case .string(let s): return s
        }
    }

    var doubleVal: Double {
        switch self {
        case .int(let v): return Double(v)
        case .double(let v): return v
        case .string(let s): return Double(s) ?? 0
        }
    }

    var isEmpty: Bool { stringVal.isEmpty || stringVal == "0" }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let i = try? c.decode(Int.self) { self = .int(i) }
        else if let d = try? c.decode(Double.self) { self = .double(d) }
        else if let s = try? c.decode(String.self) { self = .string(s) }
        else { self = .string("") }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .int(let v): try c.encode(v)
        case .double(let v): try c.encode(v)
        case .string(let s): try c.encode(s)
        }
    }

    static func from(_ value: Any?) -> LenientScalar {
        guard let value else { return .string("") }
        if let i = value as? Int { return .int(i) }
        if let d = value as? Double { return .double(d) }
        if let n = value as? NSNumber { return .double(n.doubleValue) }
        if let s = value as? String { return .string(s) }
        return .string("")
    }

    static func fromOptional(_ value: Any?) -> LenientScalar? {
        guard let value else { return nil }
        if let i = value as? Int { return .int(i) }
        if let d = value as? Double { return .double(d) }
        if let n = value as? NSNumber { return .double(n.doubleValue) }
        if let s = value as? String { return s.isEmpty ? nil : .string(s) }
        return nil
    }
}

/// `actor` and `director` arrays mix bare strings with
/// `{name, character, profile_url}` objects.
enum PersonRef: Codable, Hashable, Identifiable {
    case plain(String)
    case detailed(name: String, character: String, profileURL: String)

    var id: String { name + character }

    var name: String {
        switch self {
        case .plain(let n): return n
        case .detailed(let n, _, _): return n
        }
    }

    var character: String {
        if case .detailed(_, let c, _) = self { return c }
        return ""
    }

    var profileURL: String {
        if case .detailed(_, _, let url) = self { return url }
        return ""
    }

    private struct Detailed: Codable {
        let name: String?
        let character: String?
        let profile_url: String?
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) {
            self = .plain(s)
            return
        }
        let obj = try c.decode(Detailed.self)
        self = .detailed(name: obj.name ?? "",
                         character: obj.character ?? "",
                         profileURL: obj.profile_url ?? "")
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .plain(let n):
            try c.encode(n)
        case .detailed(let n, let ch, let url):
            try c.encode(Detailed(name: n, character: ch, profile_url: url))
        }
    }
}
