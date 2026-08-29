import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var state
    @State private var viewModel = HomeViewModel()

    var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .top) {
                DFColor.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DFSpacing.sectionH) {
                        Color.clear
                            .frame(height: 0)
                            .id("home_top_anchor")

                        // Spacing for sticky top header
                        Color.clear
                            .frame(height: 52)

                        HeroSection(hero: viewModel.hero, isLoading: viewModel.isLoading && viewModel.hero.isEmpty)

                        ContinueWatchingSection(items: state.localStore.history().prefix(6).map { $0 })

                        ForEach(viewModel.homeRows) { row in
                            MovieRowSection(title: row.title, movies: row.items, filter: row.catalogFilter)
                        }

                        rankingSections

                        if !viewModel.isLoading && !viewModel.homeRows.isEmpty {
                            latestSection
                        }

                        CommentSection(movieKey: "dragonfilm_homepage",
                                       movieName: "DragonFilm", title: "Bình luận chung")

                        if viewModel.isLoading && viewModel.homeRows.isEmpty {
                            HStack(spacing: DFSpacing.md) {
                                ProgressView()
                                    .tint(DFColor.gold)
                                Text("Đang tải dữ liệu...")
                                    .font(DFFont.caption())
                                    .foregroundStyle(DFColor.textMuted)
                            }
                            .padding(.vertical, DFSpacing.xxxl)
                        }

                        if let loadError = viewModel.loadError, viewModel.homeRows.isEmpty {
                            VStack(spacing: DFSpacing.lg) {
                                Image(systemName: "wifi.exclamationmark")
                                    .font(.system(size: 44))
                                    .foregroundStyle(DFColor.goldDim)
                                Text(loadError)
                                    .font(DFFont.body())
                                    .foregroundStyle(DFColor.textDim)
                                    .multilineTextAlignment(.center)
                                Button("Thử lại") {
                                    Task {
                                        await viewModel.loadHome(force: true)
                                        await viewModel.loadRankings(force: true)
                                    }
                                }
                                .font(DFFont.headline())
                                .foregroundStyle(DFColor.bg)
                                .padding(.horizontal, DFSpacing.xxl)
                                .padding(.vertical, DFSpacing.md)
                                .background(DFColor.gold)
                                .clipShape(RoundedRectangle(cornerRadius: DFRadius.md))
                            }
                            .padding(.horizontal, DFSpacing.xxl)
                            .padding(.top, DFSpacing.xxxl)
                        }
                    }
                    .padding(.bottom, DFSpacing.xxxl)
                }
                .refreshable {
                    await viewModel.loadHome(force: true)
                    await viewModel.loadRankings(force: true)
                    await state.cloudSync.sync()
                }

                // Sticky Top Header
                topHeader(proxy: proxy)
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadHome()
                await viewModel.loadRankings()
                await state.cloudSync.sync()
            }
        }
    }

    private func topHeader(proxy: ScrollViewProxy) -> some View {
        HStack(alignment: .center) {
            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    proxy.scrollTo("home_top_anchor", anchor: .top)
                }
            } label: {
                HStack(spacing: 8) {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 32)
                        .shadow(color: DFColor.gold.opacity(0.35), radius: 6)

                    Text("DRAGONFILM")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(DFColor.goldGradient)
                        .tracking(1.4)
                        .shadow(color: DFColor.gold.opacity(0.3), radius: 6)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            NavigationLink {
                SearchView()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DFColor.gold)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(DFColor.glassBorderGradient, lineWidth: 0.8))
                    .shadow(color: Color.black.opacity(0.4), radius: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DFSpacing.xxl)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(
            DFColor.bg.opacity(0.92)
                .background(.ultraThinMaterial)
                .overlay(
                    VStack {
                        Spacer()
                        Divider()
                            .overlay(Color.white.opacity(0.08))
                    }
                )
                .ignoresSafeArea(edges: .top)
        )
    }

    @ViewBuilder
    private var rankingSections: some View {
        if !viewModel.netflix.isEmpty {
            RankingPanel(title: "Netflix Việt Nam", subtitle: "Top 10 phim thịnh hành",
                         badgeLabel: "Netflix VN", badgeColor: Color(hex: 0xC1121F)) {
                ForEach(rankColumns(viewModel.netflix.count)) { column in
                    VStack(spacing: DFSpacing.sm) {
                        ForEach(column.range, id: \.self) { i in
                            let item = viewModel.netflix[i]
                            RankingLink(titles: [item.title], year: nil) {
                                NetflixRankingRow(item: item, rank: item.rank)
                            }
                            if i < column.range.upperBound - 1 {
                                Divider().overlay(DFColor.border.opacity(0.3))
                            }
                        }
                    }
                    .padding(DFSpacing.lg)
                    .frame(width: 320)
                    .background(DFColor.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: DFRadius.lg)
                            .stroke(DFColor.border.opacity(0.35), lineWidth: 0.5)
                    )
                }
            }
        }

        if !viewModel.tmdbKR.isEmpty {
            RankingPanel(title: "Phim Hàn hot hit", subtitle: "TV series được quan tâm",
                         badgeLabel: "TMDB Hàn", badgeColor: DFColor.steel) {
                ForEach(rankColumns(viewModel.tmdbKR.count)) { column in
                    VStack(spacing: DFSpacing.sm) {
                        ForEach(column.range, id: \.self) { i in
                            let item = viewModel.tmdbKR[i]
                            RankingLink(titles: [item.title, item.originalTitle].compactMap { $0 },
                                        year: nil) {
                                TMDBRankingRow(item: item, rank: item.rank)
                            }
                            if i < column.range.upperBound - 1 {
                                Divider().overlay(DFColor.border.opacity(0.3))
                            }
                        }
                    }
                    .padding(DFSpacing.lg)
                    .frame(width: 320)
                    .background(DFColor.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: DFRadius.lg)
                            .stroke(DFColor.border.opacity(0.35), lineWidth: 0.5)
                    )
                }
            }
        }

        if !viewModel.tmdbCN.isEmpty {
            RankingPanel(title: "Top phim Trung tuần", subtitle: "TV series nổi bật",
                         badgeLabel: "TMDB Trung", badgeColor: DFColor.goldDim) {
                ForEach(rankColumns(viewModel.tmdbCN.count)) { column in
                    VStack(spacing: DFSpacing.sm) {
                        ForEach(column.range, id: \.self) { i in
                            let item = viewModel.tmdbCN[i]
                            RankingLink(titles: [item.title, item.originalTitle].compactMap { $0 },
                                        year: nil) {
                                TMDBRankingRow(item: item, rank: item.rank)
                            }
                            if i < column.range.upperBound - 1 {
                                Divider().overlay(DFColor.border.opacity(0.3))
                            }
                        }
                    }
                    .padding(DFSpacing.lg)
                    .frame(width: 320)
                    .background(DFColor.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: DFRadius.lg)
                            .stroke(DFColor.border.opacity(0.35), lineWidth: 0.5)
                    )
                }
            }
        }

        if !viewModel.animeWeekly.isEmpty {
            RankingPanel(title: "Anime tuần", subtitle: "Trending AniList",
                         badgeLabel: "AniList", badgeColor: DFColor.sage) {
                ForEach(rankColumns(viewModel.animeWeekly.count)) { column in
                    VStack(spacing: DFSpacing.sm) {
                        ForEach(column.range, id: \.self) { i in
                            let item = viewModel.animeWeekly[i]
                            RankingLink(titles: [item.titleEN, item.titleRomaji, item.titleNative]
                                            .filter { !$0.isEmpty },
                                        year: item.year > 0 ? String(item.year) : nil) {
                                AniListRankingRow(item: item, rank: i + 1)
                            }
                            if i < column.range.upperBound - 1 {
                                Divider().overlay(DFColor.border.opacity(0.3))
                            }
                        }
                    }
                    .padding(DFSpacing.lg)
                    .frame(width: 320)
                    .background(DFColor.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: DFRadius.lg)
                            .stroke(DFColor.border.opacity(0.35), lineWidth: 0.5)
                    )
                }
            }
        }

        if !viewModel.animeSeason.isEmpty {
            RankingPanel(title: "Anime mùa", subtitle: viewModel.seasonLabel,
                         badgeLabel: "Season", badgeColor: DFColor.gold.opacity(0.85)) {
                ForEach(rankColumns(viewModel.animeSeason.count)) { column in
                    VStack(spacing: DFSpacing.sm) {
                        ForEach(column.range, id: \.self) { i in
                            let item = viewModel.animeSeason[i]
                            RankingLink(titles: [item.titleEN, item.titleRomaji, item.titleNative]
                                            .filter { !$0.isEmpty },
                                        year: item.year > 0 ? String(item.year) : nil) {
                                AniListRankingRow(item: item, rank: i + 1)
                            }
                            if i < column.range.upperBound - 1 {
                                Divider().overlay(DFColor.border.opacity(0.3))
                            }
                        }
                    }
                    .padding(DFSpacing.lg)
                    .frame(width: 320)
                    .background(DFColor.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: DFRadius.lg)
                            .stroke(DFColor.border.opacity(0.35), lineWidth: 0.5)
                    )
                }
            }
        }
    }

    /// Infinite-scroll grid replacing the web's paginated "Phim Mới Cập Nhật".
    @ViewBuilder
    private var latestSection: some View {
        VStack(alignment: .leading, spacing: DFSpacing.lg) {
            HStack {
                SectionHeader(title: viewModel.latestTitle)
                Spacer()
                Button { viewModel.showFilters = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        Text("Bộ lọc")
                    }
                    .font(DFFont.caption())
                    .foregroundStyle(DFColor.gold)
                    .padding(.horizontal, DFSpacing.md)
                    .padding(.vertical, 6)
                    .background(DFColor.gold.opacity(0.12))
                    .clipShape(Capsule())
                }
                .padding(.trailing, DFSpacing.xxl)
            }

            let cardWidth = (UIScreen.main.bounds.width - DFSpacing.xxl * 2 - DFSpacing.md * 2) / 3

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DFSpacing.md), count: 3),
                      spacing: DFSpacing.xl) {
                ForEach(viewModel.latest) { movie in
                    NavigationLink {
                        MovieDetailView(slug: movie.slug)
                    } label: {
                        PosterCard(imageURL: movie.bestPoster, title: movie.name,
                                   subtitle: movie.yearString, badge: movie.episodeCurrent,
                                   width: cardWidth)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if movie.id == viewModel.latest.last?.id {
                            Task { await viewModel.loadMoreLatest() }
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
        .task {
            if viewModel.filter.isEmpty { await viewModel.loadLatest() }
        }
        .sheet(isPresented: $viewModel.showFilters) {
            FilterSheet(selection: viewModel.filter) { newFilter in
                Task { await viewModel.applyFilter(newFilter) }
            }
        }
    }

    private func rankColumns(_ count: Int) -> [RankColumn] {
        stride(from: 0, to: count, by: 5).map { start in
            RankColumn(start: start, end: min(start + 5, count))
        }
    }
}

struct RankColumn: Identifiable {
    let start: Int
    let end: Int
    var id: Int { start }
    var range: Range<Int> { start..<end }
}

struct HeroSection: View {
    let hero: [Movie]
    var isLoading: Bool = false
    @State private var selectedIndex = 0

    var body: some View {
        Group {
            if isLoading {
                RoundedRectangle(cornerRadius: DFRadius.xl)
                    .fill(DFColor.bg3)
                    .frame(height: 460)
                    .padding(.horizontal, DFSpacing.xxl)
                    .shimmer()
            } else if !hero.isEmpty {
                VStack(spacing: 12) {
                    TabView(selection: $selectedIndex) {
                        ForEach(Array(hero.prefix(5).enumerated()), id: \.offset) { index, movie in
                            NavigationLink {
                                MovieDetailView(slug: movie.slug)
                            } label: {
                                ZStack(alignment: .bottomLeading) {
                                    // Hero Banner
                                    RemoteImage(url: movie.bestBanner, contentMode: .fill)
                                        .frame(width: UIScreen.main.bounds.width - DFSpacing.xxl * 2, height: 440)
                                        .clipped()
                                        .overlay(
                                            LinearGradient(
                                                stops: [
                                                    .init(color: .clear, location: 0.0),
                                                    .init(color: DFColor.bg.opacity(0.3), location: 0.35),
                                                    .init(color: DFColor.bg.opacity(0.85), location: 0.75),
                                                    .init(color: DFColor.bg, location: 1.0)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: DFRadius.xl))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DFRadius.xl)
                                                .stroke(DFColor.glassBorderGradient, lineWidth: 0.8)
                                        )
                                        .shadow(color: Color.black.opacity(0.7), radius: 16, y: 8)

                                    // Content overlay
                                    VStack(alignment: .leading, spacing: 10) {
                                        // Category & Year Badges
                                        HStack(spacing: 6) {
                                            HStack(spacing: 3) {
                                                Image(systemName: "flame.fill")
                                                    .font(.system(size: 10))
                                                Text("NỔI BẬT")
                                                    .font(DFFont.small())
                                            }
                                            .foregroundStyle(DFColor.gold)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3.5)
                                            .background(
                                                Capsule()
                                                    .fill(DFColor.gold.opacity(0.18))
                                                    .overlay(Capsule().stroke(DFColor.gold.opacity(0.4), lineWidth: 0.6))
                                            )

                                            if !movie.yearString.isEmpty {
                                                Text(movie.yearString)
                                                    .font(DFFont.small())
                                                    .foregroundStyle(.white)
                                                    .padding(.horizontal, 7)
                                                    .padding(.vertical, 3.5)
                                                    .background(Color.white.opacity(0.15))
                                                    .clipShape(Capsule())
                                            }

                                            if !movie.episodeCurrent.isEmpty {
                                                Text(movie.episodeCurrent)
                                                    .font(DFFont.small())
                                                    .foregroundStyle(.white)
                                                    .padding(.horizontal, 7)
                                                    .padding(.vertical, 3.5)
                                                    .background(DFColor.crimson.opacity(0.85))
                                                    .clipShape(Capsule())
                                            }
                                        }

                                        // Movie Title
                                        Text(movie.name)
                                            .font(DFFont.heroTitle())
                                            .foregroundStyle(.white)
                                            .lineLimit(2)
                                            .shadow(color: .black.opacity(0.8), radius: 6, y: 3)

                                        if !movie.originName.isEmpty {
                                            Text(movie.originName)
                                                .font(DFFont.callout())
                                                .foregroundStyle(DFColor.textDim)
                                                .lineLimit(1)
                                        }

                                        // Action Button Row
                                        HStack(spacing: 12) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "play.fill")
                                                    .font(.system(size: 13, weight: .bold))
                                                Text("Xem Ngay")
                                                    .font(DFFont.headline())
                                            }
                                            .foregroundStyle(Color(hex: 0x07080A))
                                            .padding(.horizontal, 22)
                                            .padding(.vertical, 10)
                                            .background(DFColor.goldGradient)
                                            .clipShape(Capsule())
                                            .shadow(color: DFColor.gold.opacity(0.45), radius: 10, y: 3)

                                            HStack(spacing: 6) {
                                                Image(systemName: "info.circle")
                                                    .font(.system(size: 14))
                                                Text("Chi Tiết")
                                                    .font(DFFont.callout())
                                            }
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color.white.opacity(0.14))
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.8))
                                        }
                                        .padding(.top, 4)
                                    }
                                    .padding(DFSpacing.xl)
                                }
                                .padding(.horizontal, DFSpacing.xxl)
                            }
                            .buttonStyle(.plain)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 440)

                    // Custom Animated Page Indicators
                    HStack(spacing: 6) {
                        ForEach(0..<min(hero.count, 5), id: \.self) { idx in
                            Capsule()
                                .fill(selectedIndex == idx ? DFColor.gold : Color.white.opacity(0.25))
                                .frame(width: selectedIndex == idx ? 20 : 6, height: 6)
                                .animation(.spring(response: 0.35), value: selectedIndex)
                        }
                    }
                }
            }
        }
    }
}

struct ContinueWatchingSection: View {
    let items: [HistoryItem]

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: DFSpacing.lg) {
                SectionHeader(title: "Tiếp Tục Xem")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DFSpacing.lg) {
                        ForEach(items) { item in
                            NavigationLink {
                                MovieDetailView(slug: item.slug)
                            } label: {
                                ContinueWatchingCard(item: item, width: 220)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DFSpacing.xxl)
                }
            }
        }
    }
}

struct MovieRowSection: View {
    let title: String
    let movies: [Movie]
    var filter: CatalogFilter? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DFSpacing.lg) {
            if let filter {
                HStack(alignment: .center, spacing: 10) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DFColor.goldGradient)
                        .frame(width: 3.5, height: 18)
                        .shadow(color: DFColor.gold.opacity(0.6), radius: 6)

                    Text(title)
                        .font(DFFont.title2())
                        .foregroundStyle(DFColor.text)

                    Spacer()

                    NavigationLink {
                        CatalogView(title: title, initialFilter: filter)
                    } label: {
                        HStack(spacing: 3) {
                            Text("Xem thêm")
                                .font(DFFont.caption().bold())
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(DFColor.gold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(DFColor.gold.opacity(0.12))
                                .overlay(Capsule().stroke(DFColor.gold.opacity(0.25), lineWidth: 0.6))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, DFSpacing.xxl)
            } else {
                SectionHeader(title: title)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DFSpacing.lg) {
                    ForEach(movies) { movie in
                        NavigationLink {
                            MovieDetailView(slug: movie.slug)
                        } label: {
                            PosterCard(imageURL: movie.bestPoster, title: movie.name,
                                       subtitle: movie.yearString, badge: movie.type,
                                       width: 124)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DFSpacing.xxl)
            }
        }
    }
}

extension HomeRow {
    var catalogFilter: CatalogFilter {
        let lk = key.lowercased()
        let lt = title.lowercased()
        if lk.contains("bo") || lk.contains("series") || lt.contains("bộ") {
            return CatalogFilter(kind: .type, slug: "phim-bo", label: title)
        } else if lk.contains("le") || lk.contains("single") || lt.contains("lẻ") {
            return CatalogFilter(kind: .type, slug: "phim-le", label: title)
        } else if lk.contains("hoat-hinh") || lk.contains("anime") || lt.contains("hoạt hình") {
            return CatalogFilter(kind: .type, slug: "hoat-hinh", label: title)
        } else if lk.contains("tv") || lk.contains("shows") || lt.contains("tv shows") {
            return CatalogFilter(kind: .type, slug: "tv-shows", label: title)
        } else if let genre = CatalogOption.genres.first(where: { lk.contains($0.slug) || lt.contains($0.name.lowercased()) }) {
            return CatalogFilter(kind: .genre, slug: genre.slug, label: genre.name)
        } else if let country = CatalogOption.countries.first(where: { lk.contains($0.slug) || lt.contains($0.name.lowercased()) }) {
            return CatalogFilter(kind: .country, slug: country.slug, label: country.name)
        }
        return CatalogFilter(kind: .latest, slug: key, label: title)
    }
}

@Observable
final class HomeViewModel {
    var homeRows: [HomeRow] = []
    var hero: [Movie] = []
    var isLoading = false
    var loadError: String?

    var netflix: [NetflixItem] = []
    var tmdbKR: [TMDBWeeklyItem] = []
    var tmdbCN: [TMDBWeeklyItem] = []
    var animeWeekly: [AniListNormalized] = []
    var animeSeason: [AniListNormalized] = []
    var seasonLabel = "Trending mùa này"
    private var rankingsLoaded = false

    var latest: [Movie] = []
    var latestPage = 1
    var totalPages = 1
    var isLoadingMore = false
    var showFilters = false
    var filter = CatalogFilter()

    var latestTitle: String {
        filter.isEmpty ? "Phim Mới Cập Nhật" : filter.displayTitle
    }

    func loadHome(force: Bool = false) async {
        if !homeRows.isEmpty && !force { return }
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            let response: HomeResponse = try await APIClient.shared.get("/api/home")
            homeRows = response.rows
            hero = Array(response.rows.first?.items.prefix(4) ?? [])
        } catch {
            loadError = (error as? LocalizedError)?.errorDescription
                ?? "Không tải được dữ liệu. Kiểm tra kết nối mạng."
        }
    }

    func loadRankings(force: Bool = false) async {
        if rankingsLoaded && !force { return }
        rankingsLoaded = true

        await withTaskGroup(of: RankingPayload.self) { group in
            group.addTask {
                let r: NetflixResponse? = try? await APIClient.shared.get("/api/netflix-top10-vn")
                return .netflix(Array((r?.items ?? []).prefix(20)))
            }
            group.addTask {
                let r: TMDBWeeklyResponse? = try? await APIClient.shared.get(
                    "/api/tmdb-weekly", query: ["country": "KR"])
                return .tmdbKR(r?.ok == true ? r!.items : [])
            }
            group.addTask {
                let r: TMDBWeeklyResponse? = try? await APIClient.shared.get(
                    "/api/tmdb-weekly", query: ["country": "CN"])
                return .tmdbCN(r?.ok == true ? r!.items : [])
            }
            group.addTask {
                .animeWeekly((try? await AniListClient.weeklyTrending(limit: 12)) ?? [])
            }
            group.addTask {
                guard let result = try? await AniListClient.seasonRanking(limit: 12) else {
                    return .animeSeason([], nil)
                }
                return .animeSeason(result.items, result.label)
            }

            for await payload in group {
                switch payload {
                case .netflix(let items): netflix = items
                case .tmdbKR(let items): tmdbKR = items
                case .tmdbCN(let items): tmdbCN = items
                case .animeWeekly(let items): animeWeekly = items
                case .animeSeason(let items, let label):
                    animeSeason = items
                    if let label {
                        seasonLabel = "Trending \(label) \(Calendar.current.component(.year, from: .now))"
                    }
                }
            }
        }
    }

    private enum RankingPayload: Sendable {
        case netflix([NetflixItem])
        case tmdbKR([TMDBWeeklyItem])
        case tmdbCN([TMDBWeeklyItem])
        case animeWeekly([AniListNormalized])
        case animeSeason([AniListNormalized], String?)
    }

    // MARK: - Latest grid (infinite scroll)

    func loadLatest() async {
        guard latest.isEmpty else { return }
        await fetchLatest(page: 1, replacing: true)
    }

    func loadMoreLatest() async {
        guard !isLoadingMore, latestPage < totalPages else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        await fetchLatest(page: latestPage + 1, replacing: false)
    }

    func applyFilter(_ newFilter: CatalogFilter) async {
        filter = newFilter
        latest = []
        latestPage = 1
        totalPages = 1
        await fetchLatest(page: 1, replacing: true)
    }

    private func fetchLatest(page: Int, replacing: Bool) async {
        do {
            let (movies, pages) = try await SourceClient.list(
                server: .kkphim,
                operation: filter.operation,
                slug: filter.slug,
                page: page
            )
            if replacing {
                latest = movies
            } else {
                let existing = Set(latest.map(\.slug))
                latest.append(contentsOf: movies.filter { !existing.contains($0.slug) })
            }
            latestPage = page
            totalPages = pages
        } catch {
            if replacing { latest = [] }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(AppState())
}
