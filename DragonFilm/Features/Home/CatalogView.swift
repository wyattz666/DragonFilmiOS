import SwiftUI

struct CatalogView: View {
    let title: String
    let initialFilter: CatalogFilter

    @State private var viewModel = CatalogViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DFSpacing.xl) {
                // Server selector pills
                serverPicker

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
                        message: "Thử chọn nguồn phát (Server) khác ở trên."
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
            .padding(.top, DFSpacing.lg)
            .padding(.bottom, DFSpacing.xxxl)
        }
        .background(DFColor.bg)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(filter: initialFilter)
        }
    }

    private var serverPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DFSpacing.sm) {
                ForEach(SourceServer.allCases) { s in
                    Button {
                        viewModel.switchServer(s)
                    } label: {
                        Text(s.displayName)
                            .font(DFFont.caption().bold())
                            .foregroundStyle(viewModel.selectedServer == s ? Color(hex: 0x07080A) : .white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedServer == s ? DFColor.gold : Color.white.opacity(0.08))
                                    .overlay(
                                        Capsule()
                                            .stroke(viewModel.selectedServer == s ? DFColor.gold : Color.white.opacity(0.12), lineWidth: 0.6)
                                    )
                            )
                            .shadow(color: viewModel.selectedServer == s ? DFColor.gold.opacity(0.3) : .clear, radius: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DFSpacing.xxl)
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
    var selectedServer: SourceServer = .kkphim
    private var currentFilter: CatalogFilter = CatalogFilter()

    func load(filter: CatalogFilter) async {
        self.currentFilter = filter
        self.page = 1
        self.movies = []
        await fetch(page: 1, replacing: true)
    }

    func switchServer(_ server: SourceServer) {
        guard selectedServer != server else { return }
        selectedServer = server
        self.page = 1
        self.movies = []
        Task { await fetch(page: 1, replacing: true) }
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

        do {
            let (fetched, total) = try await SourceClient.list(
                server: selectedServer,
                operation: currentFilter.operation,
                slug: currentFilter.slug.isEmpty ? nil : currentFilter.slug,
                keyword: nil,
                page: page
            )
            self.page = page
            self.totalPages = max(total, page)
            if replacing {
                self.movies = fetched
            } else {
                self.movies.append(contentsOf: fetched)
            }
        } catch {
            if replacing { self.movies = [] }
        }
    }
}
