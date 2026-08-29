import SwiftUI

struct CatalogView: View {
    let title: String
    let initialFilter: CatalogFilter

    @State private var viewModel = CatalogViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DFSpacing.xl) {
                if viewModel.isLoading && viewModel.movies.isEmpty {
                    VStack(spacing: DFSpacing.md) {
                        ProgressView().tint(DFColor.gold)
                        Text("Đang tải danh sách phim...")
                            .font(DFFont.caption())
                            .foregroundStyle(DFColor.textMuted)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else if viewModel.movies.isEmpty {
                    EmptyStateView(
                        icon: "film.stack",
                        title: "Không có phim nào",
                        message: "Không tìm thấy phim phù hợp trong danh mục này."
                    )
                    .frame(minHeight: 300)
                } else {
                    let cardWidth = (UIScreen.main.bounds.width - DFSpacing.xxl * 2 - DFSpacing.md * 2) / 3

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DFSpacing.md), count: 3),
                              spacing: DFSpacing.xl) {
                        ForEach(viewModel.movies) { movie in
                            NavigationLink {
                                MovieDetailView(slug: movie.slug)
                            } label: {
                                PosterCard(
                                    imageURL: movie.bestPoster,
                                    title: movie.name,
                                    subtitle: movie.yearString,
                                    badge: movie.episodeCurrent.isEmpty ? movie.quality : movie.episodeCurrent,
                                    width: cardWidth
                                )
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                if movie.id == viewModel.movies.last?.id {
                                    Task { await viewModel.loadMore() }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DFSpacing.xxl)

                    if viewModel.isLoadingMore {
                        ProgressView()
                            .tint(DFColor.gold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DFSpacing.xl)
                    }
                }
            }
            .padding(.top, DFSpacing.md)
            .padding(.bottom, DFSpacing.xxxl)
        }
        .background(DFColor.bg)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(filter: initialFilter)
        }
    }
}

@Observable
final class CatalogViewModel {
    var movies: [Movie] = []
    var page = 1
    var totalPages = 1
    var isLoading = false
    var isLoadingMore = false
    private var currentFilter: CatalogFilter = CatalogFilter()

    func load(filter: CatalogFilter) async {
        self.currentFilter = filter
        self.page = 1
        self.movies = []
        await fetch(page: 1, replacing: true)
    }

    func loadMore() async {
        guard !isLoadingMore, page < totalPages else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        await fetch(page: page + 1, replacing: false)
    }

    private func fetch(page: Int, replacing: Bool) async {
        if replacing { isLoading = true }
        defer { if replacing { isLoading = false } }

        var collected: [Movie] = []
        var maxTotal = 1

        await withTaskGroup(of: ([Movie], Int).self) { group in
            for server in SourceServer.allCases {
                group.addTask { [server, currentFilter = self.currentFilter] in
                    do {
                        let (movies, total) = try await SourceClient.list(
                            server: server,
                            operation: currentFilter.operation,
                            slug: currentFilter.slug.isEmpty ? nil : currentFilter.slug,
                            keyword: nil,
                            page: page
                        )
                        return (movies, total)
                    } catch {
                        return ([], 1)
                    }
                }
            }

            for await (movies, total) in group {
                collected.append(contentsOf: movies)
                if total > maxTotal { maxTotal = total }
            }
        }

        // Deduplicate movies by commentKey / normalized name
        var seen = Set<String>()
        var deduplicated: [Movie] = []
        for movie in collected {
            let key = movie.commentKey.isEmpty ? movie.slug : movie.commentKey
            if !seen.contains(key) {
                seen.insert(key)
                deduplicated.append(movie)
            }
        }

        self.page = page
        self.totalPages = maxTotal
        if replacing {
            self.movies = deduplicated
        } else {
            for existing in self.movies {
                let key = existing.commentKey.isEmpty ? existing.slug : existing.commentKey
                seen.insert(key)
            }
            let fresh = deduplicated.filter { movie in
                let key = movie.commentKey.isEmpty ? movie.slug : movie.commentKey
                return !seen.contains(key)
            }
            self.movies.append(contentsOf: fresh)
        }
    }
}
