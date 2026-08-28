import SwiftUI

/// Tap target for a ranking row. Rankings come from Netflix/TMDB/AniList, which
/// have no DragonFilm slug — so a tap searches all 4 upstream servers by title
/// and navigates to the first match. No match falls back to a toast.
struct RankingLink<Label: View>: View {
    let titles: [String]
    let year: String?
    @ViewBuilder let label: () -> Label

    @State private var isSearching = false
    @State private var target: String?
    @State private var showNotFound = false

    var body: some View {
        Button {
            guard !isSearching, !titles.isEmpty else { return }
            Task { await resolve() }
        } label: {
            label()
                .opacity(isSearching ? 0.45 : 1)
                .overlay {
                    if isSearching {
                        ProgressView().tint(DFColor.gold)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(isSearching)
        .navigationDestination(item: $target) { slug in
            MovieDetailView(slug: slug)
        }
        .toast($showNotFound, message: "Không tìm thấy nguồn phát cho phim này.")
    }

    private func resolve() async {
        isSearching = true
        defer { isSearching = false }
        for candidate in titles {
            let movies = await searchAllServers(candidate)
            if let match = bestMatch(in: movies) {
                target = match.slug
                return
            }
        }
        showNotFound = true
    }

    private func searchAllServers(_ query: String) async -> [Movie] {
        var results: [Movie] = []
        await withTaskGroup(of: [Movie].self) { group in
            for server in SourceServer.allCases {
                group.addTask { [server] in
                    do {
                        let (movies, _) = try await SourceClient.list(
                            server: server, operation: "search", keyword: query
                        )
                        return movies
                    } catch { return [] }
                }
            }
            for await batch in group { results.append(contentsOf: batch) }
        }
        return results
    }

    /// Prefers an exact title match (matching year when known), then any title
    /// match, then the top search hit.
    private func bestMatch(in movies: [Movie]) -> Movie? {
        guard !movies.isEmpty else { return nil }
        let keys = Set(titles.map(normalized))
        let yearDigits = (year ?? "").filter(\.isNumber)

        let titleMatches = movies.filter {
            keys.contains(normalized($0.name)) || keys.contains(normalized($0.originName))
        }
        if !yearDigits.isEmpty,
           let exact = titleMatches.first(where: { $0.yearString.contains(yearDigits) }) {
            return exact
        }
        return titleMatches.first ?? movies.first
    }

    private func normalized(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}
