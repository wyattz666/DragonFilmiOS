import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Glass Search Bar
            HStack(spacing: DFSpacing.md) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DFColor.gold)
                TextField("Tìm tên phim, anime, diễn viên...", text: $searchText)
                    .font(DFFont.body())
                    .foregroundStyle(DFColor.text)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit { Task { await viewModel.search(searchText) } }
                    .onChange(of: searchText) { _, newVal in
                        Task { await viewModel.debounceSearch(newVal) }
                    }
                if !searchText.isEmpty {
                    Button { searchText = ""; viewModel.clearResults() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DFColor.textMuted)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: DFRadius.lg)
            .padding(.horizontal, DFSpacing.xxl)
            .padding(.top, DFSpacing.md)
            .padding(.bottom, DFSpacing.md)

            if viewModel.results.isEmpty && !viewModel.isLoading && searchText.isEmpty {
                RecentSearchesView(history: viewModel.recentSearches) { q in
                    searchText = q
                    Task { await viewModel.search(q) }
                }
            } else if viewModel.isLoading {
                ScrollView {
                    let cardWidth = (UIScreen.main.bounds.width - DFSpacing.xxl * 2 - DFSpacing.md * 2) / 3
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DFSpacing.md), count: 3),
                              spacing: DFSpacing.xl) {
                        ForEach(0..<9, id: \.self) { _ in
                            PosterCardSkeleton(width: cardWidth)
                        }
                    }
                    .padding(.horizontal, DFSpacing.xxl)
                    .padding(.top, DFSpacing.lg)
                }
            } else if viewModel.results.isEmpty && !searchText.isEmpty {
                EmptyStateView(icon: "magnifyingglass", title: "Không tìm thấy phim",
                               message: "Thử tìm kiếm với từ khóa khác hoặc tên tiếng Anh.")
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    let cardWidth = (UIScreen.main.bounds.width - DFSpacing.xxl * 2 - DFSpacing.md * 2) / 3
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DFSpacing.md), count: 3),
                              spacing: DFSpacing.xl) {
                        ForEach(viewModel.results) { movie in
                            NavigationLink {
                                MovieDetailView(slug: movie.slug)
                            } label: {
                                PosterCard(imageURL: movie.bestPoster, title: movie.name,
                                           subtitle: movie.yearString, badge: movie.episodeCurrent,
                                           width: cardWidth)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DFSpacing.xxl)
                    .padding(.top, DFSpacing.lg)
                    .padding(.bottom, DFSpacing.xxxl)
                }
            }
            Spacer(minLength: 0)
        }
        .background(DFColor.bg)
        .navigationTitle("Tìm Kiếm")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadRecentSearches() }
    }
}

struct RecentSearchesView: View {
    let history: [String]
    let onSelect: (String) -> Void

    private let discoverTags = ["Anime Mùa Này", "Phim Chiếu Rạp", "Phim Hàn Quốc", "Phim Trung Quốc", "Top Netflix", "Hành Động"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DFSpacing.xl) {
                // Quick Discover Tags
                VStack(alignment: .leading, spacing: DFSpacing.md) {
                    SectionHeader(title: "Khám Phá Nhanh")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(discoverTags, id: \.self) { tag in
                                Button {
                                    onSelect(tag)
                                } label: {
                                    Text(tag)
                                        .font(DFFont.caption())
                                        .foregroundStyle(DFColor.text)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(DFColor.cardBg)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(DFColor.glassBorderGradient, lineWidth: 0.7))
                                }
                            }
                        }
                        .padding(.horizontal, DFSpacing.xxl)
                    }
                }

                if !history.isEmpty {
                    VStack(alignment: .leading, spacing: DFSpacing.md) {
                        SectionHeader(title: "Tìm Gần Đây")
                        VStack(spacing: 6) {
                            ForEach(history, id: \.self) { query in
                                Button { onSelect(query) } label: {
                                    HStack(spacing: DFSpacing.lg) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .foregroundStyle(DFColor.gold)
                                            .font(.subheadline)
                                        Text(query)
                                            .font(DFFont.body())
                                            .foregroundStyle(DFColor.text)
                                        Spacer()
                                        Image(systemName: "arrow.up.left")
                                            .font(.caption2)
                                            .foregroundStyle(DFColor.textMuted)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, DFSpacing.lg)
                                    .glassCard(cornerRadius: DFRadius.md)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, DFSpacing.xxl)
                    }
                }
            }
            .padding(.top, DFSpacing.lg)
        }
    }
}

@Observable
final class SearchViewModel {
    var results: [Movie] = []
    var recentSearches: [String] = []
    var isLoading = false
    private let store = LocalStore()
    private var searchTask: Task<Void, Never>?

    func loadRecentSearches() {
        recentSearches = store.recentSearches()
    }

    func debounceSearch(_ query: String) async {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }
        let task = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await self?.search(query)
        }
        searchTask = task
        await task.value
    }

    func search(_ query: String) async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        store.addSearch(q)
        recentSearches = store.recentSearches()

        var seen: [String: Movie] = [:]
        await withTaskGroup(of: [Movie].self) { group in
            for server in SourceServer.allCases {
                group.addTask { [server] in
                    do {
                        let (movies, _) = try await SourceClient.list(server: server, operation: "search", keyword: q)
                        return movies
                    } catch { return [] }
                }
            }
            for await movies in group {
                for movie in movies {
                    let key = "\(movie.name.lowercased()):\(movie.yearString)"
                    if seen[key] == nil { seen[key] = movie }
                }
            }
        }
        results = Array(seen.values).sorted { $0.name < $1.name }
    }

    func clearResults() {
        results = []
        recentSearches = store.recentSearches()
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
    .environment(AppState())
}
