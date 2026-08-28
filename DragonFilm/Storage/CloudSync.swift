import Foundation

/// Two-way merge between LocalStore and the cloud `/api/user-data` endpoint.
/// Fully compatible with the DragonFilm web client (v4 cloud-data schema).
final class CloudSync {
    private let store: LocalStore
    private let auth: AuthManager

    init(store: LocalStore, auth: AuthManager) {
        self.store = store
        self.auth = auth
    }

    /// Pull latest changes, merge locally, and push updated state to cloud.
    func sync() async {
        guard let token = auth.token else { return }
        do {
            // 1. Pull latest from cloud
            let remoteResponse: DataResponse = try await APIClient.shared.get(
                "/api/user-data", token: token
            )
            let remoteSnapshot = decodeSnapshot(remoteResponse.data?.mapValues(\.value))
            merge(remoteSnapshot)

            // 2. Notify LocalStore on MainActor so SwiftUI views update immediately
            await MainActor.run {
                store.notifyDataChanged()
            }

            // 3. Build complete local snapshot (with web-compatible structure)
            let local = Snapshot(
                history: store.history(),
                resumeTimes: store.resumeTimes(),
                watchLater: store.watchLater(),
                liked: store.likedMovies(),
                actors: store.favoriteActors()
            )
            let payload: [String: Any] = [
                "data": try encodeSnapshot(local)
            ]

            // 4. Push to server
            let _: DataResponse = try await APIClient.shared.post(
                "/api/user-data", body: payload, token: token
            )
        } catch {
            // Offline or error — local data stays safe
        }
    }

    // MARK: - Merge

    private func merge(_ remote: Snapshot) {
        // History: keep whichever has the newer watchedAt per movie slug
        let localHistory = store.history()
        var historyMap: [String: HistoryItem] = [:]
        for item in localHistory {
            guard !item.slug.isEmpty else { continue }
            if let existing = historyMap[item.slug] {
                if item.watchedAt > existing.watchedAt {
                    historyMap[item.slug] = item
                }
            } else {
                historyMap[item.slug] = item
            }
        }
        for item in remote.history {
            guard !item.slug.isEmpty else { continue }
            if let existing = historyMap[item.slug] {
                if item.watchedAt > existing.watchedAt {
                    historyMap[item.slug] = item
                }
            } else {
                historyMap[item.slug] = item
            }
        }
        let mergedHistory = Array(historyMap.values)
            .sorted { $0.watchedAt > $1.watchedAt }
            .prefix(50)
        store.save("history.json", Array(mergedHistory))

        // Merge resume times
        var localTimes = store.resumeTimes()
        for (k, v) in remote.resumeTimes {
            if (localTimes[k] ?? 0) < v {
                localTimes[k] = v
            }
        }
        store.setResumeTimes(localTimes)

        // WatchLater, liked, actors: union by slug/name
        mergeLibrary(file: "watchLater.json", remote: remote.watchLater) { $0.slug }
        mergeLibrary(file: "liked.json", remote: remote.liked) { $0.slug }
        mergeLibrary(file: "actors.json", remote: remote.actors) { $0.name }
    }

    private func mergeLibrary<T: Codable & Identifiable>(file: String, remote: [T], key: (T) -> String) {
        let local: [T] = store.load(file) ?? []
        var map = Dictionary(local.map { (key($0), $0) }, uniquingKeysWith: { first, _ in first })
        for item in remote {
            let k = key(item)
            guard !k.isEmpty else { continue }
            if map[k] == nil {
                map[k] = item
            }
        }
        store.save(file, Array(map.values))
    }

    // MARK: - Snapshot

    struct Snapshot {
        var history: [HistoryItem] = []
        var resumeTimes: [String: Double] = [:]
        var watchLater: [Movie] = []
        var liked: [Movie] = []
        var actors: [SavedActor] = []
    }

    private func encodeSnapshot(_ s: Snapshot) throws -> [String: Any] {
        let enc = JSONEncoder()
        let historyJSON = try JSONSerialization.jsonObject(with: try enc.encode(s.history))
        let watchLaterJSON = try JSONSerialization.jsonObject(with: try enc.encode(s.watchLater))
        let likedJSON = try JSONSerialization.jsonObject(with: try enc.encode(s.liked))
        let actorsJSON = try JSONSerialization.jsonObject(with: try enc.encode(s.actors))

        return [
            "app": "dragonfilm",
            "type": "cloud-data",
            "version": 4,
            "savedAt": ISO8601DateFormatter().string(from: Date()),
            "history": historyJSON,
            "resumeTimes": s.resumeTimes,
            "movieLibrary": [
                "watchLater": watchLaterJSON,
                "liked": likedJSON
            ],
            "actorLibrary": actorsJSON
        ]
    }

    private func decodeSnapshot(_ dict: [String: Any]?) -> Snapshot {
        guard let dict else { return Snapshot() }
        let dec = JSONDecoder()

        // Handle nested movieLibrary { watchLater: [], liked: [] }
        var watchLater: [Movie] = []
        var liked: [Movie] = []
        if let movieLib = dict["movieLibrary"] as? [String: Any] {
            watchLater = decodeArr(movieLib["watchLater"], dec: dec) ?? []
            liked = decodeArr(movieLib["liked"], dec: dec) ?? []
        } else {
            watchLater = decodeArr(dict["watchLater"], dec: dec) ?? []
            liked = decodeArr(dict["liked"], dec: dec) ?? []
        }

        // Handle actorLibrary or actors
        let actors: [SavedActor] = decodeArr(dict["actorLibrary"], dec: dec)
            ?? decodeArr(dict["actors"], dec: dec)
            ?? []

        let history: [HistoryItem] = decodeArr(dict["history"], dec: dec) ?? []

        var resumeTimes: [String: Double] = [:]
        if let times = dict["resumeTimes"] as? [String: Any] {
            for (k, v) in times {
                if let d = v as? Double { resumeTimes[k] = d }
                else if let i = v as? Int { resumeTimes[k] = Double(i) }
                else if let s = v as? String, let d = Double(s) { resumeTimes[k] = d }
            }
        }

        return Snapshot(
            history: history,
            resumeTimes: resumeTimes,
            watchLater: watchLater,
            liked: liked,
            actors: actors
        )
    }

    private func decodeArr<T: Decodable>(_ val: Any?, dec: JSONDecoder) -> [T]? {
        guard let arr = val as? [Any] else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: arr) else { return nil }
        return try? dec.decode([T].self, from: data)
    }

    private struct DataResponse: Decodable {
        let ok: Bool?
        let data: [String: AnyCodable]?
    }
}
