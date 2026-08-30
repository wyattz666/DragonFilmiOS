import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var state
    @State private var viewModel = HomeViewModel()

    var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .top) {
                DFColor.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: 1)
                            .id("home_top_anchor")

                        // Spacing for sticky top header and category pills
                        Color.clear
                            .frame(height: 107)

                        if !viewModel.filter.isEmpty {
                            // Active Filter Results Grid
                            filteredCatalogSection
                        } else {
                            // Standard Home Feed Content
                            standardHomeFeed
                        }
                    }
                    .padding(.bottom, DFSpacing.xxxl)
                }
                .refreshable {
                    if !viewModel.filter.isEmpty {
                        await viewModel.applyFilter(viewModel.filter)
                    } else {
                        await viewModel.loadHome(force: true)
                        await viewModel.loadRankings(force: true)
                        await state.cloudSync.sync()
                    }
                }

                // Sticky Unified Cinema Top Header & Category Navigation Bar
                stickyHeader(proxy: proxy)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showFilterSheet) {
                FilterSheet(selection: viewModel.filter, initialKind: viewModel.filterSheetKind) { newFilter in
                    Task {
                        await viewModel.applyFilter(newFilter)
                    }
                }
            }
            .task {
                await viewModel.loadHome()
                await viewModel.loadRankings()
                await state.cloudSync.sync()
            }
        }
    }

    // MARK: - Sticky Header & Category Navigation

    private func stickyHeader(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 8) {
            // Brand & Actions Bar
            HStack(alignment: .center) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
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
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
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
                            .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.openFilter(kind: nil)
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(viewModel.filter.isEmpty ? .white : Color(hex: 0x07080A))
                            .frame(width: 38, height: 38)
                            .background(viewModel.filter.isEmpty ? Color.white.opacity(0.12) : DFColor.gold)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(viewModel.filter.isEmpty ? Color.white.opacity(0.18) : Color.clear, lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DFSpacing.xxl)
            .padding(.top, 4)

            // Category Navigation Filter Chips
            categoryPills(proxy: proxy)
        }
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                stops: [
                    .init(color: DFColor.bg.opacity(0.96), location: 0.0),
                    .init(color: DFColor.bg.opacity(0.88), location: 0.75),
                    .init(color: DFColor.bg.opacity(0.0), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    private func categoryPills(proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 1. "Đề xuất" (Default home feed)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if viewModel.filter.isEmpty {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            proxy.scrollTo("home_top_anchor", anchor: .top)
                        }
                    } else {
                        Task {
                            await viewModel.applyFilter(CatalogFilter())
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                proxy.scrollTo("home_top_anchor", anchor: .top)
                            }
                        }
                    }
                } label: {
                    Text("Đề xuất")
                        .font(DFFont.caption().bold())
                        .foregroundStyle(viewModel.filter.isEmpty ? Color(hex: 0x07080A) : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(viewModel.filter.isEmpty ? Color.white : Color.white.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(viewModel.filter.isEmpty ? Color.clear : Color.white.opacity(0.18), lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)

                // 2. "Phim bộ"
                let isPhimBo = viewModel.filter.kind == .type && viewModel.filter.slug == "phim-bo"
                Button {
                    Task {
                        if isPhimBo {
                            await viewModel.applyFilter(CatalogFilter())
                        } else {
                            await viewModel.applyFilter(CatalogFilter(kind: .type, slug: "phim-bo", label: "Phim Bộ"))
                        }
                    }
                } label: {
                    Text("Phim bộ")
                        .font(DFFont.caption().bold())
                        .foregroundStyle(isPhimBo ? Color(hex: 0x07080A) : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(isPhimBo ? DFColor.gold : Color.white.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(isPhimBo ? Color.clear : Color.white.opacity(0.18), lineWidth: 0.8))
                }
                .buttonStyle(.plain)

                // 3. "Phim lẻ"
                let isPhimLe = viewModel.filter.kind == .type && viewModel.filter.slug == "phim-le"
                Button {
                    Task {
                        if isPhimLe {
                            await viewModel.applyFilter(CatalogFilter())
                        } else {
                            await viewModel.applyFilter(CatalogFilter(kind: .type, slug: "phim-le", label: "Phim Lẻ"))
                        }
                    }
                } label: {
                    Text("Phim lẻ")
                        .font(DFFont.caption().bold())
                        .foregroundStyle(isPhimLe ? Color(hex: 0x07080A) : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(isPhimLe ? DFColor.gold : Color.white.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(isPhimLe ? Color.clear : Color.white.opacity(0.18), lineWidth: 0.8))
                }
                .buttonStyle(.plain)

                // 4. "Hoạt hình"
                let isHoatHinh = viewModel.filter.kind == .type && viewModel.filter.slug == "hoat-hinh"
                Button {
                    Task {
                        if isHoatHinh {
                            await viewModel.applyFilter(CatalogFilter())
                        } else {
                            await viewModel.applyFilter(CatalogFilter(kind: .type, slug: "hoat-hinh", label: "Hoạt Hình"))
                        }
                    }
                } label: {
                    Text("Hoạt hình")
                        .font(DFFont.caption().bold())
                        .foregroundStyle(isHoatHinh ? Color(hex: 0x07080A) : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(isHoatHinh ? DFColor.gold : Color.white.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(isHoatHinh ? Color.clear : Color.white.opacity(0.18), lineWidth: 0.8))
                }
                .buttonStyle(.plain)

                // 5. "Thể loại ⌄" (Opens Genre Sheet Popup)
                let isGenre = viewModel.filter.kind == .genre
                Button {
                    viewModel.openFilter(kind: .genre)
                } label: {
                    HStack(spacing: 4) {
                        Text(isGenre ? viewModel.filter.label : "Thể loại")
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .font(DFFont.caption().bold())
                    .foregroundStyle(isGenre ? Color(hex: 0x07080A) : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(isGenre ? DFColor.gold : Color.white.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(isGenre ? Color.clear : Color.white.opacity(0.18), lineWidth: 0.8))
                }
                .buttonStyle(.plain)

                // 6. "Quốc gia ⌄" (Opens Country Sheet Popup)
                let isCountry = viewModel.filter.kind == .country
                Button {
                    viewModel.openFilter(kind: .country)
                } label: {
                    HStack(spacing: 4) {
                        Text(isCountry ? viewModel.filter.label : "Quốc gia")
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .font(DFFont.caption().bold())
                    .foregroundStyle(isCountry ? Color(hex: 0x07080A) : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(isCountry ? DFColor.gold : Color.white.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(isCountry ? Color.clear : Color.white.opacity(0.18), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DFSpacing.xxl)
        }
    }

    // MARK: - Active Filter Catalog Section

    @ViewBuilder
    private var filteredCatalogSection: some View {
        VStack(alignment: .leading, spacing: DFSpacing.lg) {
            // Filter Bar Indicator
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .foregroundStyle(DFColor.gold)
                    Text(viewModel.filter.displayTitle)
                        .font(DFFont.headline())
                        .foregroundStyle(.white)
                }

                Spacer()

                Button {
                    Task {
                        await viewModel.applyFilter(CatalogFilter())
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Xóa lọc")
                    }
                    .font(DFFont.caption().bold())
                    .foregroundStyle(DFColor.gold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(DFColor.gold.opacity(0.15))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DFSpacing.xxl)
            .padding(.top, DFSpacing.sm)

            if viewModel.isLoadingFiltered {
                HStack(spacing: DFSpacing.md) {
                    ProgressView()
                        .tint(DFColor.gold)
                    Text("Đang tải danh sách phim...")
                        .font(DFFont.caption())
                        .foregroundStyle(DFColor.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DFSpacing.xxxl)
            } else if viewModel.filteredMovies.isEmpty {
                VStack(spacing: DFSpacing.md) {
                    Image(systemName: "film")
                        .font(.system(size: 40))
                        .foregroundStyle(DFColor.textMuted)
                    Text("Không tìm thấy phim phù hợp.")
                        .font(DFFont.body())
                        .foregroundStyle(DFColor.textDim)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DFSpacing.xxxl)
            } else {
                let cardWidth = (UIScreen.main.bounds.width - DFSpacing.xxl * 2 - DFSpacing.md * 2) / 3

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DFSpacing.md), count: 3),
                          spacing: DFSpacing.xl) {
                    ForEach(viewModel.filteredMovies) { movie in
                        NavigationLink {
                            MovieDetailView(slug: movie.slug)
                        } label: {
                            PosterCard(imageURL: movie.bestPoster, title: movie.name,
                                       subtitle: movie.yearString, badge: movie.episodeCurrent,
                                       width: cardWidth)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            if movie.id == viewModel.filteredMovies.last?.id {
                                Task { await viewModel.loadMoreFiltered() }
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
    }

    // MARK: - Standard Home Feed

    @ViewBuilder
    private var standardHomeFeed: some View {
        VStack(spacing: DFSpacing.sectionH) {
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
        .padding(.top, DFSpacing.sm)
    }

    // MARK: - Rankings

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
            RankingPanel(title: "Phim Trung hot hit", subtitle: "TV series được quan tâm",
                         badgeLabel: "TMDB Trung", badgeColor: Color(hex: 0x9B2226)) {
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

    // MARK: - Latest Grid (Infinite Scroll)

    @ViewBuilder
    private var latestSection: some View {
        VStack(alignment: .leading, spacing: DFSpacing.lg) {
            SectionHeader(title: "Phim Mới Cập Nhật")

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

            if viewModel.isLoadingMoreLatest {
                ProgressView()
                    .tint(DFColor.gold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DFSpacing.xl)
            }
        }
        .task {
            await viewModel.loadLatest()
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

// MARK: - HomeViewModel

@Observable
final class HomeViewModel {
    var homeRows: [HomeRow] = []
    var isLoading = false
    var loadError: String?

    var netflix: [NetflixItem] = []
    var tmdbKR: [TMDBWeeklyItem] = []
    var tmdbCN: [TMDBWeeklyItem] = []
    var animeWeekly: [AniListNormalized] = []
    var animeSeason: [AniListNormalized] = []
    var seasonLabel = "Trending mùa này"
    private var rankingsLoaded = false

    // Catalog Filtering In-Place
    var filter = CatalogFilter()
    var showFilterSheet = false
    var filterSheetKind: CatalogFilter.Kind? = nil

    var filteredMovies: [Movie] = []
    var filteredPage = 1
    var filteredTotalPages = 1
    var isLoadingFiltered = false
    var isLoadingMore = false

    // Latest Section
    var latest: [Movie] = []
    var latestPage = 1
    var latestTotalPages = 1
    var isLoadingMoreLatest = false

    func openFilter(kind: CatalogFilter.Kind? = nil) {
        filterSheetKind = kind
        showFilterSheet = true
    }

    func applyFilter(_ newFilter: CatalogFilter) async {
        filter = newFilter
        if filter.isEmpty {
            filteredMovies = []
            filteredPage = 1
            return
        }
        filteredMovies = []
        filteredPage = 1
        filteredTotalPages = 1
        await fetchFiltered(page: 1, replacing: true)
    }

    func loadMoreFiltered() async {
        guard !isLoadingMore, filteredPage < filteredTotalPages else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        await fetchFiltered(page: filteredPage + 1, replacing: false)
    }

    private func fetchFiltered(page: Int, replacing: Bool) async {
        if replacing { isLoadingFiltered = true }
        defer { if replacing { isLoadingFiltered = false } }

        var collected: [Movie] = []
        var maxTotal = 1

        await withTaskGroup(of: ([Movie], Int).self) { group in
            for server in SourceServer.allCases {
                group.addTask { [server, filter = self.filter] in
                    do {
                        let (movies, total) = try await SourceClient.list(
                            server: server,
                            operation: filter.operation,
                            slug: filter.slug.isEmpty ? nil : filter.slug,
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

        var seen = Set<String>()
        var deduplicated: [Movie] = []
        for movie in collected {
            let key = movie.commentKey.isEmpty ? movie.slug : movie.commentKey
            if !seen.contains(key) {
                seen.insert(key)
                deduplicated.append(movie)
            }
        }

        if replacing {
            filteredMovies = deduplicated
        } else {
            let existing = Set(filteredMovies.map(\.slug))
            filteredMovies.append(contentsOf: deduplicated.filter { !existing.contains($0.slug) })
        }
        filteredPage = page
        filteredTotalPages = maxTotal
    }

    // MARK: - Data Loading

    func loadHome(force: Bool = false) async {
        if !homeRows.isEmpty && !force { return }
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            let response: HomeResponse = try await APIClient.shared.get("/api/home")
            homeRows = response.rows
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

    // MARK: - Latest Grid (Infinite Scroll)

    func loadLatest() async {
        guard latest.isEmpty else { return }
        await fetchLatest(page: 1, replacing: true)
    }

    func loadMoreLatest() async {
        guard !isLoadingMoreLatest, latestPage < latestTotalPages else { return }
        isLoadingMoreLatest = true
        defer { isLoadingMoreLatest = false }
        await fetchLatest(page: latestPage + 1, replacing: false)
    }

    private func fetchLatest(page: Int, replacing: Bool) async {
        var collected: [Movie] = []
        var maxTotal = 1

        await withTaskGroup(of: ([Movie], Int).self) { group in
            for server in SourceServer.allCases {
                group.addTask {
                    do {
                        let (movies, total) = try await SourceClient.list(
                            server: server,
                            operation: "latest",
                            slug: nil,
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

        var seen = Set<String>()
        var deduplicated: [Movie] = []
        for movie in collected {
            let key = movie.commentKey.isEmpty ? movie.slug : movie.commentKey
            if !seen.contains(key) {
                seen.insert(key)
                deduplicated.append(movie)
            }
        }

        if replacing {
            latest = deduplicated
        } else {
            let existing = Set(latest.map(\.slug))
            latest.append(contentsOf: deduplicated.filter { !existing.contains($0.slug) })
        }
        latestPage = page
        latestTotalPages = maxTotal
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(AppState())
}
