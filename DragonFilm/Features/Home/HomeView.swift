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
                HStack(spacing: 10) {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 36)
                        .shadow(color: DFColor.gold.opacity(0.35), radius: 6)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("DragonFilm")
                            .font(.system(size: 19, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Phim Chuẩn Điện Ảnh")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(DFColor.textMuted)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 10) {
                NavigationLink {
                    SearchView()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.8))
                }
                .buttonStyle(.plain)

                NavigationLink {
                    CatalogView(title: "Bộ Lọc Phim", initialFilter: CatalogFilter())
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DFSpacing.xxl)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(
            LinearGradient(
                stops: [
                    .init(color: DFColor.bg.opacity(0.88), location: 0.0),
                    .init(color: DFColor.bg.opacity(0.4), location: 0.65),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
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
    @State private var activeHeroId: Int? = 0

    private var selectedIndex: Int {
        activeHeroId ?? 0
    }

    private var currentMovie: Movie? {
        guard !hero.isEmpty, selectedIndex >= 0, selectedIndex < hero.count else { return hero.first }
        return hero[selectedIndex]
    }

    private let cardWidth: CGFloat = 220
    private let cardHeight: CGFloat = 320

    var body: some View {
        Group {
            if isLoading {
                RoundedRectangle(cornerRadius: DFRadius.xl)
                    .fill(DFColor.bg3)
                    .frame(height: 520)
                    .padding(.horizontal, DFSpacing.xxl)
                    .shimmer()
            } else if !hero.isEmpty {
                ZStack(alignment: .top) {
                    // Immersive Ambient Blurred Backdrop Background
                    if let movie = currentMovie {
                        RemoteImage(url: movie.bestPoster, contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 560)
                            .clipped()
                            .blur(radius: 50)
                            .opacity(0.44)
                            .overlay(
                                LinearGradient(
                                    stops: [
                                        .init(color: DFColor.bg.opacity(0.4), location: 0.0),
                                        .init(color: .clear, location: 0.25),
                                        .init(color: DFColor.bg.opacity(0.7), location: 0.65),
                                        .init(color: DFColor.bg.opacity(0.95), location: 0.9),
                                        .init(color: DFColor.bg, location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .offset(y: -50)
                            .animation(.easeInOut(duration: 0.4), value: selectedIndex)
                    }

                    VStack(spacing: 14) {
                        // Category Navigation Filter Chips
                        categoryPills

                        // 3D CoverFlow Card Carousel
                        cardCarousel

                        // Active Movie Details, Action Buttons, Badges, & Page Indicators
                        if let movie = currentMovie {
                            movieInfoSection(movie)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Active "Đề xuất" pill
                Text("Đề xuất")
                    .font(DFFont.caption().bold())
                    .foregroundStyle(Color(hex: 0x07080A))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.white.opacity(0.25), radius: 4)

                NavigationLink {
                    CatalogView(title: "Phim Bộ", initialFilter: CatalogFilter(kind: .type, slug: "phim-bo", label: "Phim Bộ"))
                } label: {
                    Text("Phim bộ")
                        .font(DFFont.caption().bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                }

                NavigationLink {
                    CatalogView(title: "Phim Lẻ", initialFilter: CatalogFilter(kind: .type, slug: "phim-le", label: "Phim Lẻ"))
                } label: {
                    Text("Phim lẻ")
                        .font(DFFont.caption().bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                }

                NavigationLink {
                    CatalogView(title: "Khám Phá Thể Loại", initialFilter: CatalogFilter())
                } label: {
                    HStack(spacing: 4) {
                        Text("Thể loại")
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .font(DFFont.caption().bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                }
            }
            .padding(.horizontal, DFSpacing.xxl)
        }
    }

    private var cardCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(Array(hero.prefix(8).enumerated()), id: \.offset) { index, movie in
                    NavigationLink {
                        MovieDetailView(slug: movie.slug)
                    } label: {
                        RemoteImage(url: movie.bestPoster, contentMode: .fill)
                            .frame(width: cardWidth, height: cardHeight)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(selectedIndex == index ? 0.25 : 0.08), lineWidth: 1.0)
                            )
                            .shadow(color: Color.black.opacity(selectedIndex == index ? 0.85 : 0.4), radius: selectedIndex == index ? 16 : 8, y: selectedIndex == index ? 10 : 4)
                    }
                    .buttonStyle(.plain)
                    .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                        content
                            .scaleEffect(phase.isIdentity ? 1.0 : 0.86)
                            .opacity(phase.isIdentity ? 1.0 : 0.58)
                            .rotation3DEffect(
                                .degrees(phase.value * -14),
                                axis: (x: 0, y: 1, z: 0)
                            )
                    }
                    .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $activeHeroId)
        .safeAreaPadding(.horizontal, max(0, (UIScreen.main.bounds.width - cardWidth) / 2))
        .frame(height: cardHeight + 10)
    }

    private func movieInfoSection(_ movie: Movie) -> some View {
        VStack(spacing: 12) {
            // Movie Title & Original Name
            VStack(spacing: 4) {
                Text(movie.name)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.8), radius: 6, y: 3)

                if !movie.originName.isEmpty {
                    Text(movie.originName)
                        .font(DFFont.caption())
                        .foregroundStyle(DFColor.textMuted)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, DFSpacing.xl)

            // Primary Action Buttons Row
            HStack(spacing: 12) {
                NavigationLink {
                    MovieDetailView(slug: movie.slug)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Xem Phim")
                            .font(DFFont.headline())
                    }
                    .foregroundStyle(Color(hex: 0x07080A))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(DFColor.goldGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: DFColor.gold.opacity(0.4), radius: 8, y: 3)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    MovieDetailView(slug: movie.slug)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 15))
                        Text("Thông tin")
                            .font(DFFont.headline())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.white.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DFSpacing.xxl)
            .padding(.top, 2)

            // Badges Row
            HStack(spacing: 6) {
                // Rating Pill (IMDb 9.6 / TMDB 8.8)
                let score = movie.formattedScore
                Text("\(score.label) \(score.score)")
                    .font(DFFont.caption().bold())
                    .foregroundStyle(DFColor.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(
                        Capsule()
                            .fill(DFColor.gold.opacity(0.15))
                            .overlay(Capsule().stroke(DFColor.gold.opacity(0.5), lineWidth: 0.8))
                    )

                // Quality Pill (HD)
                Text(movie.cleanQuality)
                    .font(DFFont.small().bold())
                    .foregroundStyle(Color(hex: 0x07080A))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(DFColor.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                // Year Pill (2026)
                if !movie.yearString.isEmpty {
                    Text(movie.yearString)
                        .font(DFFont.caption().bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                // Episode Pill
                Text(movie.episodeBadge)
                    .font(DFFont.caption().bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            // Genre Line
            Text(movie.categoryString)
                .font(DFFont.caption().bold())
                .foregroundStyle(DFColor.goldDim)
                .lineLimit(1)

            // Pagination Dots
            HStack(spacing: 5) {
                ForEach(0..<min(hero.count, 8), id: \.self) { idx in
                    if selectedIndex == idx {
                        Capsule()
                            .fill(DFColor.goldGradient)
                            .frame(width: 22, height: 4)
                            .animation(.spring(response: 0.35), value: selectedIndex)
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.28))
                            .frame(width: 4.5, height: 4.5)
                            .animation(.spring(response: 0.35), value: selectedIndex)
                    }
                }
            }
            .padding(.top, 4)
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
