import Foundation
import SwiftUI

/// Local persistence using JSON files in Application Support.
/// Keys mirror the web localStorage to maintain conceptual compatibility,
/// but the local file store is more reliable than UserDefaults for large blobs
/// (the web stores history + library as single JSON documents up to ~200 items).
@Observable
final class LocalStore {
    var historyUpdateCount: Int = 0
    var libraryUpdateCount: Int = 0
    private let dir: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        dir = base.appendingPathComponent("dragonfilm")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    // MARK: - History

    func history() -> [HistoryItem] {
        _ = historyUpdateCount
        let list: [HistoryItem] = load("history.json") ?? []
        var seen = Set<String>()
        var unique: [HistoryItem] = []
        for item in list {
            guard !item.slug.isEmpty else { continue }
            if !seen.contains(item.slug) {
                seen.insert(item.slug)
                unique.append(item)
            }
        }
        return unique
    }

    func addToHistory(_ item: HistoryItem) {
        guard !item.slug.isEmpty else { return }
        var list = history()
        list.removeAll { $0.slug == item.slug }
        list.insert(item, at: 0)
        if list.count > 50 { list = Array(list.prefix(50)) }
        save("history.json", list)
        historyUpdateCount += 1
    }

    func removeFromHistory(slug: String) {
        var list = history()
        list.removeAll { $0.slug == slug }
        save("history.json", list)
        var times = resumeTimes()
        times.removeValue(forKey: slug)
        save("resumeTimes.json", times)
        historyUpdateCount += 1
    }

    func clearHistory() {
        save("history.json", [] as [HistoryItem])
        save("resumeTimes.json", [:] as [String: Double])
        historyUpdateCount += 1
    }

    func clear(_ tab: LibraryTab) {
        switch tab {
        case .history:
            save("history.json", [] as [HistoryItem])
            save("resumeTimes.json", [:] as [String: Double])
            historyUpdateCount += 1
        case .watchLater:
            save("watchLater.json", [] as [Movie])
            libraryUpdateCount += 1
        case .liked:
            save("liked.json", [] as [Movie])
            libraryUpdateCount += 1
        case .actors:
            save("actors.json", [] as [SavedActor])
            libraryUpdateCount += 1
        }
    }

    // MARK: - Watch Later

    func watchLater() -> [Movie] {
        _ = libraryUpdateCount
        return load("watchLater.json") ?? []
    }

    func toggleWatchLater(_ movie: Movie) {
        var list = watchLater()
        if let idx = list.firstIndex(where: { $0.slug == movie.slug }) {
            list.remove(at: idx)
        } else {
            list.insert(movie, at: 0)
            if list.count > 200 { list = Array(list.prefix(200)) }
        }
        save("watchLater.json", list)
        libraryUpdateCount += 1
    }

    func removeFromWatchLater(slug: String) {
        var list = watchLater()
        list.removeAll { $0.slug == slug }
        save("watchLater.json", list)
        libraryUpdateCount += 1
    }

    func isWatchLater(_ slug: String) -> Bool {
        watchLater().contains { $0.slug == slug }
    }

    // MARK: - Liked Movies

    func likedMovies() -> [Movie] {
        _ = libraryUpdateCount
        return load("liked.json") ?? []
    }

    func toggleLiked(_ movie: Movie) {
        var list = likedMovies()
        if let idx = list.firstIndex(where: { $0.slug == movie.slug }) {
            list.remove(at: idx)
        } else {
            list.insert(movie, at: 0)
            if list.count > 200 { list = Array(list.prefix(200)) }
        }
        save("liked.json", list)
        libraryUpdateCount += 1
    }

    func removeFromLiked(slug: String) {
        var list = likedMovies()
        list.removeAll { $0.slug == slug }
        save("liked.json", list)
        libraryUpdateCount += 1
    }

    func isLiked(_ slug: String) -> Bool {
        likedMovies().contains { $0.slug == slug }
    }

    // MARK: - Actors

    func favoriteActors() -> [SavedActor] {
        _ = libraryUpdateCount
        return load("actors.json") ?? []
    }

    func isFavoriteActor(_ name: String) -> Bool {
        favoriteActors().contains { $0.name == name }
    }

    func toggleFavoriteActor(_ actor: PersonRef) {
        var list = favoriteActors()
        if let idx = list.firstIndex(where: { $0.name == actor.name }) {
            list.remove(at: idx)
        } else {
            let saved = SavedActor(name: actor.name, character: actor.character,
                                   profileURL: actor.profileURL, addedAt: Date().timeIntervalSince1970)
            list.insert(saved, at: 0)
            if list.count > 200 { list = Array(list.prefix(200)) }
        }
        save("actors.json", list)
        libraryUpdateCount += 1
    }

    func removeFromActors(name: String) {
        var list = favoriteActors()
        list.removeAll { $0.name == name }
        save("actors.json", list)
        libraryUpdateCount += 1
    }

    // MARK: - Resume Times

    func resumeTimes() -> [String: Double] {
        load("resumeTimes.json") ?? [:]
    }

    func resumeTime(for slug: String) -> Double {
        let times = resumeTimes()
        return times[slug] ?? 0
    }

    func setResumeTime(_ seconds: Double, for slug: String) {
        guard seconds > 5 else { return }
        var times = resumeTimes()
        times[slug] = seconds
        save("resumeTimes.json", times)
    }

    func setResumeTimes(_ times: [String: Double]) {
        save("resumeTimes.json", times)
    }

    // MARK: - Search History

    func recentSearches() -> [String] {
        load("searchHistory.json") ?? []
    }

    func addSearch(_ query: String) {
        var list = recentSearches()
        list.removeAll { $0.lowercased() == query.lowercased() }
        list.insert(query, at: 0)
        if list.count > 20 { list = Array(list.prefix(20)) }
        save("searchHistory.json", list)
    }

    // MARK: - VIP Avatar Frame

    func selectedVIPFrame() -> String? {
        _ = libraryUpdateCount
        return UserDefaults.standard.string(forKey: "df_selected_vip_frame")
    }

    func setVIPFrame(_ frameId: String?) {
        if let frameId {
            UserDefaults.standard.set(frameId, forKey: "df_selected_vip_frame")
        } else {
            UserDefaults.standard.removeObject(forKey: "df_selected_vip_frame")
        }
        libraryUpdateCount += 1
    }

    // MARK: - Server preference

    var lastUsedServer: SourceServer {
        get {
            let raw: String = load("serverPref.json") ?? "kkphim"
            return SourceServer(rawValue: raw) ?? .kkphim
        }
        set { save("serverPref.json", newValue.rawValue) }
    }

    // MARK: - UI Reactivity Helper

    @MainActor
    func notifyDataChanged() {
        historyUpdateCount += 1
        libraryUpdateCount += 1
    }

    // MARK: - Persistence Helpers

    func save<T: Encodable>(_ filename: String, _ value: T) {
        let url = dir.appendingPathComponent(filename)
        let data = try? JSONEncoder().encode(value)
        try? data?.write(to: url, options: .atomic)
    }

    func load<T: Decodable>(_ filename: String) -> T? {
        let url = dir.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

struct HistoryItem: Codable, Identifiable {
    let slug: String
    let name: String
    let posterURL: String
    let year: String
    let server: String
    let sourceName: String
    let episodeName: String
    let episodeSlug: String
    let episodeServerName: String
    let episodeServerIdx: Int
    let episodeIndex0: Int
    let episodeNumber: Int
    let watchedSeconds: Double
    let durationSeconds: Double
    let watchedAt: Double

    var id: String { "\(slug)-\(episodeSlug)" }

    var progress: Double {
        if durationSeconds > 0 {
            return max(0.0, min(1.0, watchedSeconds / durationSeconds))
        }
        return 0.0
    }

    var progressPercentText: String {
        let p = Int(round(progress * 100))
        return "\(p)%"
    }

    init(movie: Movie, episode: Episode, server: String, serverIdx: Int = 0, epIndex: Int = 0,
         watchedSeconds: Double = 0, durationSeconds: Double = 0) {
        self.slug = movie.slug
        self.name = movie.name
        self.posterURL = movie.bestPoster
        self.year = movie.yearString
        self.server = server
        self.sourceName = ""
        self.episodeName = episode.name
        self.episodeSlug = episode.slug
        self.episodeServerName = server
        self.episodeServerIdx = serverIdx
        self.episodeIndex0 = epIndex
        self.episodeNumber = epIndex + 1
        self.watchedSeconds = watchedSeconds
        self.durationSeconds = durationSeconds
        self.watchedAt = Date().timeIntervalSince1970
    }

    enum CodingKeys: String, CodingKey {
        case slug, name, year
        case posterURL = "poster_url"
        case posterURLAlt = "posterURL"
        case thumbURL = "thumb_url"
        case thumbURLAlt = "thumbURL"
        case server = "_server"
        case serverAlt = "server"
        case sourceName = "source_name"
        case sourceNameAlt = "sourceName"
        case episodeName = "episode_name"
        case episodeNameAlt = "episodeName"
        case episodeSlug = "episode_slug"
        case episodeSlugAlt = "episodeSlug"
        case episodeServerName = "episode_server_name"
        case episodeServerNameAlt = "episodeServerName"
        case episodeServerIdx = "episode_server_idx"
        case episodeServerIdxAlt = "episodeServerIdx"
        case episodeIndex0 = "episode_index0"
        case episodeIndex0Alt = "episodeIndex0"
        case episodeNumber = "episode_number"
        case episodeNumberAlt = "episodeNumber"
        case watchedSeconds = "watched_seconds"
        case watchedSecondsAlt = "watchedSeconds"
        case durationSeconds = "duration_seconds"
        case durationSecondsAlt = "durationSeconds"
        case duration = "duration"
        case watchedAt
        case watchedAtAlt = "watched_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.slug = (try? c.decode(String.self, forKey: .slug)) ?? ""
        self.name = (try? c.decode(String.self, forKey: .name)) ?? ""
        self.posterURL = (try? c.decode(String.self, forKey: .posterURL))
            ?? (try? c.decode(String.self, forKey: .posterURLAlt))
            ?? (try? c.decode(String.self, forKey: .thumbURL))
            ?? (try? c.decode(String.self, forKey: .thumbURLAlt)) ?? ""

        if let yStr = try? c.decode(String.self, forKey: .year) {
            self.year = yStr
        } else if let yInt = try? c.decode(Int.self, forKey: .year) {
            self.year = String(yInt)
        } else {
            self.year = ""
        }

        self.server = (try? c.decode(String.self, forKey: .server))
            ?? (try? c.decode(String.self, forKey: .serverAlt)) ?? "kkphim"
        self.sourceName = (try? c.decode(String.self, forKey: .sourceName))
            ?? (try? c.decode(String.self, forKey: .sourceNameAlt)) ?? ""
        self.episodeName = (try? c.decode(String.self, forKey: .episodeName))
            ?? (try? c.decode(String.self, forKey: .episodeNameAlt)) ?? ""
        self.episodeSlug = (try? c.decode(String.self, forKey: .episodeSlug))
            ?? (try? c.decode(String.self, forKey: .episodeSlugAlt)) ?? ""
        self.episodeServerName = (try? c.decode(String.self, forKey: .episodeServerName))
            ?? (try? c.decode(String.self, forKey: .episodeServerNameAlt)) ?? ""

        if let idx = try? c.decode(Int.self, forKey: .episodeServerIdx) {
            self.episodeServerIdx = idx
        } else if let idxAlt = try? c.decode(Int.self, forKey: .episodeServerIdxAlt) {
            self.episodeServerIdx = idxAlt
        } else if let str = try? c.decode(String.self, forKey: .episodeServerIdx), let idx = Int(str) {
            self.episodeServerIdx = idx
        } else {
            self.episodeServerIdx = 0
        }

        if let idx0 = try? c.decode(Int.self, forKey: .episodeIndex0) {
            self.episodeIndex0 = idx0
        } else if let idx0Alt = try? c.decode(Int.self, forKey: .episodeIndex0Alt) {
            self.episodeIndex0 = idx0Alt
        } else if let str = try? c.decode(String.self, forKey: .episodeIndex0), let idx = Int(str) {
            self.episodeIndex0 = idx
        } else {
            self.episodeIndex0 = 0
        }

        if let num = try? c.decode(Int.self, forKey: .episodeNumber) {
            self.episodeNumber = num
        } else if let numAlt = try? c.decode(Int.self, forKey: .episodeNumberAlt) {
            self.episodeNumber = numAlt
        } else if let str = try? c.decode(String.self, forKey: .episodeNumber), let num = Int(str) {
            self.episodeNumber = num
        } else {
            self.episodeNumber = 1
        }

        if let sec = try? c.decode(Double.self, forKey: .watchedSeconds) {
            self.watchedSeconds = sec
        } else if let secAlt = try? c.decode(Double.self, forKey: .watchedSecondsAlt) {
            self.watchedSeconds = secAlt
        } else if let secInt = try? c.decode(Int.self, forKey: .watchedSeconds) {
            self.watchedSeconds = Double(secInt)
        } else if let secStr = try? c.decode(String.self, forKey: .watchedSeconds), let sec = Double(secStr) {
            self.watchedSeconds = sec
        } else {
            self.watchedSeconds = 0
        }

        if let dur = try? c.decode(Double.self, forKey: .durationSeconds) {
            self.durationSeconds = dur
        } else if let durAlt = try? c.decode(Double.self, forKey: .durationSecondsAlt) {
            self.durationSeconds = durAlt
        } else if let dur = try? c.decode(Double.self, forKey: .duration) {
            self.durationSeconds = dur
        } else if let durInt = try? c.decode(Int.self, forKey: .durationSeconds) {
            self.durationSeconds = Double(durInt)
        } else if let durStr = try? c.decode(String.self, forKey: .durationSeconds), let dur = Double(durStr) {
            self.durationSeconds = dur
        } else {
            self.durationSeconds = 0
        }

        var rawWatched: Double = Date().timeIntervalSince1970
        if let w = try? c.decode(Double.self, forKey: .watchedAt) {
            rawWatched = w
        } else if let wAlt = try? c.decode(Double.self, forKey: .watchedAtAlt) {
            rawWatched = wAlt
        } else if let wInt = try? c.decode(Int64.self, forKey: .watchedAt) {
            rawWatched = Double(wInt)
        } else if let wStr = try? c.decode(String.self, forKey: .watchedAt), let w = Double(wStr) {
            rawWatched = w
        }
        self.watchedAt = rawWatched > 10_000_000_000 ? rawWatched / 1000 : rawWatched
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(slug, forKey: .slug)
        try c.encode(name, forKey: .name)
        try c.encode(posterURL, forKey: .posterURL)
        try c.encode(year, forKey: .year)
        try c.encode(server, forKey: .server)
        try c.encode(sourceName, forKey: .sourceName)
        try c.encode(episodeName, forKey: .episodeName)
        try c.encode(episodeSlug, forKey: .episodeSlug)
        try c.encode(episodeServerName, forKey: .episodeServerName)
        try c.encode(episodeServerIdx, forKey: .episodeServerIdx)
        try c.encode(episodeIndex0, forKey: .episodeIndex0)
        try c.encode(episodeNumber, forKey: .episodeNumber)
        try c.encode(watchedSeconds, forKey: .watchedSeconds)
        try c.encode(durationSeconds, forKey: .durationSeconds)
        try c.encode(watchedAt * 1000, forKey: .watchedAt)
    }
}

struct SavedActor: Codable, Identifiable {
    let name: String
    let character: String
    let profileURL: String
    let addedAt: Double

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name, character
        case profileURL = "profile_url"
        case profileURLAlt = "profileURL"
        case addedAt
        case addedAtAlt = "added_at"
    }

    init(name: String, character: String, profileURL: String, addedAt: Double) {
        self.name = name
        self.character = character
        self.profileURL = profileURL
        self.addedAt = addedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.name = (try? c.decode(String.self, forKey: .name)) ?? ""
        self.character = (try? c.decode(String.self, forKey: .character)) ?? ""
        self.profileURL = (try? c.decode(String.self, forKey: .profileURL))
            ?? (try? c.decode(String.self, forKey: .profileURLAlt)) ?? ""
        let raw = (try? c.decode(Double.self, forKey: .addedAt))
            ?? (try? c.decode(Double.self, forKey: .addedAtAlt)) ?? Date().timeIntervalSince1970
        self.addedAt = raw > 10_000_000_000 ? raw / 1000 : raw
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(character, forKey: .character)
        try c.encode(profileURL, forKey: .profileURL)
        try c.encode(addedAt * 1000, forKey: .addedAt)
    }
}
