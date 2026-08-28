import SwiftUI

struct MovieDetailView: View {
    let slug: String
    @State private var viewModel = MovieDetailViewModel()
    @State private var playingEpisode: Episode?
    @Environment(AppState.self) private var state

    var body: some View {
        ScrollView {
            if let movie = viewModel.movie {
                VStack(alignment: .leading, spacing: DFSpacing.sectionH) {
                    detailHero(movie)
                    episodeSection
                    castSection

                    CommentSection(movieKey: movie.commentKey, movieName: movie.name)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, DFSpacing.xxxl)
            } else if viewModel.isLoading {
                VStack(spacing: DFSpacing.md) {
                    ProgressView().tint(DFColor.gold)
                    Text("Đang tải thông tin phim...")
                        .font(DFFont.caption())
                        .foregroundStyle(DFColor.textMuted)
                }
                .frame(maxWidth: .infinity, minHeight: 400)
            } else {
                EmptyStateView(icon: "film", title: "Không tìm thấy phim",
                               message: "Phim này hiện không khả dụng hoặc đã bị gỡ.")
            }
        }
        .background(DFColor.bg)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let movie = viewModel.movie {
                    ShareLink(item: "https://dragonfilm.pages.dev/detail.html?slug=\(movie.slug)") {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(DFColor.gold)
                    }
                }
            }
        }
        .fullScreenCover(item: $playingEpisode) { ep in
            if let movie = viewModel.movie {
                PlayerView(movie: movie,
                           server: viewModel.selectedServer,
                           episode: ep,
                           allEpisodes: viewModel.currentEpisodes)
            }
        }
        .task { await viewModel.load(slug: slug, token: state.auth.token) }
    }

    private func detailHero(_ movie: Movie) -> some View {
        VStack(alignment: .leading, spacing: DFSpacing.xl) {
            // Immersive Backdrop with Poster & Metadata
            ZStack(alignment: .bottomLeading) {
                RemoteImage(url: movie.bestBanner, contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width, height: 360)
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

                HStack(alignment: .bottom, spacing: DFSpacing.lg) {
                    // Floating Poster
                    RemoteImage(url: movie.bestPoster, contentMode: .fill)
                        .frame(width: 110, height: 165)
                        .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: DFRadius.lg)
                                .stroke(DFColor.glassBorderGradient, lineWidth: 0.8)
                        )
                        .shadow(color: Color.black.opacity(0.8), radius: 14, x: 0, y: 6)

                    // Title & Badges
                    VStack(alignment: .leading, spacing: 5) {
                        if !movie.yearString.isEmpty {
                            Text(movie.yearString)
                                .font(DFFont.caption())
                                .foregroundStyle(DFColor.gold)
                        }

                        Text(movie.name)
                            .font(DFFont.heroTitle())
                            .foregroundStyle(DFColor.text)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .shadow(color: .black.opacity(0.7), radius: 4, y: 2)

                        if !movie.originName.isEmpty {
                            Text(movie.originName)
                                .font(DFFont.small())
                                .foregroundStyle(DFColor.textDim)
                                .lineLimit(1)
                        }

                        HStack(spacing: DFSpacing.xs) {
                            if let q = movie.quality, !q.isEmpty {
                                Text(q)
                                    .font(DFFont.small())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2.5)
                                    .background(Color.white.opacity(0.18))
                                    .clipShape(Capsule())
                            }
                            if let l = movie.lang, !l.isEmpty {
                                Text(l)
                                    .font(DFFont.small())
                                    .foregroundStyle(DFColor.steel)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2.5)
                                    .background(DFColor.steel.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            if !movie.episodeCurrent.isEmpty {
                                Text(movie.episodeCurrent)
                                    .font(DFFont.small())
                                    .foregroundStyle(DFColor.sage)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2.5)
                                    .background(DFColor.sage.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 2)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, DFSpacing.xxl)
                .padding(.bottom, DFSpacing.xs)
            }
            .frame(width: UIScreen.main.bounds.width, height: 360)

            // Cinema Quick Info Bar (Rating, Year, Duration, Category)
            quickInfoBar(movie)
                .padding(.horizontal, DFSpacing.xxl)

            // Main Action Buttons
            actionButtons(movie)
                .padding(.horizontal, DFSpacing.xxl)

            // Description
            if !viewModel.description.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NỘI DUNG PHIM")
                        .font(DFFont.small())
                        .foregroundStyle(DFColor.textMuted)

                    Text(viewModel.description)
                        .font(DFFont.body())
                        .foregroundStyle(DFColor.textDim)
                        .lineSpacing(3)
                        .lineLimit(viewModel.showFullDesc ? nil : 3)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.showFullDesc.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.showFullDesc ? "Thu gọn" : "Xem thêm")
                            Image(systemName: viewModel.showFullDesc ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .font(DFFont.caption())
                        .foregroundStyle(DFColor.gold)
                    }
                }
                .padding(.horizontal, DFSpacing.xxl)
            }

            if viewModel.availableServers.count > 1 {
                serverBar
                    .padding(.horizontal, DFSpacing.xxl)
            }
        }
    }

    private func quickInfoBar(_ movie: Movie) -> some View {
        HStack(spacing: 0) {
            let score = (movie.tmdb?.scoreString != "N/A" ? movie.tmdb?.scoreString : nil)
                ?? (movie.imdb?.scoreString != "N/A" ? movie.imdb?.scoreString : nil)
                ?? "N/A"
            infoItem(icon: "star.fill", label: "Điểm TMDB", value: score, color: DFColor.gold)
            Divider().overlay(Color.white.opacity(0.1)).frame(height: 24)
            infoItem(icon: "calendar", label: "Năm", value: movie.yearString.isEmpty ? "2024" : movie.yearString, color: DFColor.steel)
            Divider().overlay(Color.white.opacity(0.1)).frame(height: 24)
            infoItem(icon: "film", label: "Thể loại", value: movie.category.first?.name ?? "Phim", color: DFColor.sage)
        }
        .padding(.vertical, 10)
        .glassCard(cornerRadius: DFRadius.md)
    }

    private func infoItem(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(DFFont.small())
                    .foregroundStyle(DFColor.textMuted)
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(DFColor.text)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var resumeEpisode: Episode? {
        let hist = state.localStore.history().first(where: { $0.slug == slug })
        if let hist {
            if let ep = viewModel.currentEpisodes.first(where: { $0.slug == hist.episodeSlug || $0.name == hist.episodeName }) {
                return ep
            }
            if hist.episodeIndex0 < viewModel.currentEpisodes.count {
                return viewModel.currentEpisodes[hist.episodeIndex0]
            }
        }
        return viewModel.currentEpisodes.first
    }

    private func actionButtons(_ movie: Movie) -> some View {
        let targetEp = resumeEpisode
        let isResume = state.localStore.history().contains(where: { $0.slug == slug })
        let playTitle = targetEp.map { isResume ? "Tiếp tục xem \($0.name)" : "Xem \($0.name)" } ?? "Xem Phim"

        return HStack(spacing: DFSpacing.md) {
            Button {
                if let ep = targetEp {
                    playingEpisode = ep
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text(playTitle)
                        .font(DFFont.headline())
                }
                .foregroundStyle(Color(hex: 0x07080A))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(DFColor.goldGradient)
                .clipShape(RoundedRectangle(cornerRadius: DFRadius.md))
                .shadow(color: DFColor.gold.opacity(0.4), radius: 10, y: 3)
            }
            .buttonStyle(.plain)

            Button {
                state.localStore.toggleWatchLater(movie)
                Task { await state.cloudSync.sync() }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: state.localStore.isWatchLater(movie.slug) ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(state.localStore.isWatchLater(movie.slug) ? DFColor.gold : .white)
                    Text(state.localStore.isWatchLater(movie.slug) ? "Đã lưu" : "Xem sau")
                        .font(DFFont.callout())
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, DFSpacing.lg)
                .padding(.vertical, 13)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DFRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: DFRadius.md)
                        .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                )
            }

            Button {
                state.localStore.toggleLiked(movie)
                Task { await state.cloudSync.sync() }
            } label: {
                Image(systemName: state.localStore.isLiked(movie.slug) ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(state.localStore.isLiked(movie.slug) ? .red : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DFRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DFRadius.md)
                            .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                    )
            }
        }
    }

    private var serverBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CHỌN NGUỒN PHÁT (SERVER):")
                .font(DFFont.small())
                .foregroundStyle(DFColor.textMuted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DFSpacing.md) {
                    ForEach(viewModel.availableServers) { server in
                        Button {
                            viewModel.switchServer(server)
                        } label: {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(viewModel.selectedServer == server ? DFColor.gold : Color.white.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                Text(server.displayName)
                                    .font(DFFont.caption())
                                    .foregroundStyle(viewModel.selectedServer == server ? .white : DFColor.textDim)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedServer == server ? DFColor.surface : DFColor.cardBg)
                                    .overlay(
                                        Capsule()
                                            .stroke(viewModel.selectedServer == server ? DFColor.gold : Color.white.opacity(0.1), lineWidth: 0.8)
                                    )
                            )
                        }
                    }
                }
            }
        }
    }

    private var episodeSection: some View {
        VStack(alignment: .leading, spacing: DFSpacing.md) {
            HStack {
                SectionHeader(title: "Danh Sách Tập")
                Spacer()
                if !viewModel.currentEpisodes.isEmpty {
                    Text("\(viewModel.currentEpisodes.count) tập")
                        .font(DFFont.caption())
                        .foregroundStyle(DFColor.textMuted)
                        .padding(.trailing, DFSpacing.xxl)
                }
            }

            // Audio Version Selector: Vietsub / Thuyet Minh / Long Tieng
            if viewModel.episodeServers.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DFSpacing.sm) {
                        ForEach(Array(viewModel.episodeServers.enumerated()), id: \.offset) { idx, server in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    viewModel.selectedEpisodeServerIndex = idx
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: iconForVersion(server.serverName))
                                    Text(cleanVersionTitle(server.serverName))
                                }
                                .font(DFFont.caption().bold())
                                .foregroundStyle(viewModel.selectedEpisodeServerIndex == idx ? Color(hex: 0x07080A) : .white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(viewModel.selectedEpisodeServerIndex == idx ? DFColor.gold : Color.white.opacity(0.08))
                                        .overlay(
                                            Capsule()
                                                .stroke(viewModel.selectedEpisodeServerIndex == idx ? DFColor.gold : Color.white.opacity(0.15), lineWidth: 0.6)
                                        )
                                )
                                .shadow(color: viewModel.selectedEpisodeServerIndex == idx ? DFColor.gold.opacity(0.35) : .clear, radius: 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DFSpacing.xxl)
                }
                .padding(.bottom, 4)
            }

            if viewModel.currentEpisodes.isEmpty {
                EmptyStateView(icon: "list.bullet", title: "Chưa có tập phim",
                               message: "Hãy thử chọn nguồn phát (Server) khác ở trên.")
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DFSpacing.md), count: 4),
                          spacing: DFSpacing.md) {
                    ForEach(viewModel.currentEpisodes) { ep in
                        Button {
                            playingEpisode = ep
                        } label: {
                            Text(ep.name)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(DFColor.text)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(DFColor.cardBg)
                                .clipShape(RoundedRectangle(cornerRadius: DFRadius.md))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DFRadius.md)
                                        .stroke(DFColor.glassBorderGradient, lineWidth: 0.7)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DFSpacing.xxl)
            }
        }
    }

    private func cleanVersionTitle(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("thuyet minh") || lower.contains("thuyết minh") { return "Thuyết Minh" }
        if lower.contains("long tieng") || lower.contains("lồng tiếng") { return "Lồng Tiếng" }
        if lower.contains("vietsub") || lower.contains("sub") { return "Vietsub" }
        return name
    }

    private func iconForVersion(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("thuyet minh") || lower.contains("thuyết minh") { return "waveform.badge.mic" }
        if lower.contains("long tieng") || lower.contains("lồng tiếng") { return "person.wave.2" }
        if lower.contains("vietsub") || lower.contains("sub") { return "sparkles" }
        return "film.stack"
    }

    private var castSection: some View {
        Group {
            if let actors = viewModel.movie?.actor, !actors.isEmpty {
                VStack(alignment: .leading, spacing: DFSpacing.lg) {
                    SectionHeader(title: "Diễn Viên")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DFSpacing.xl) {
                            ForEach(actors) { actor in
                                Button {
                                    state.localStore.toggleFavoriteActor(actor)
                                    Task { await state.cloudSync.sync() }
                                } label: {
                                    VStack(spacing: 6) {
                                        ZStack(alignment: .bottomTrailing) {
                                            RemoteImage(url: actor.profileURL, contentMode: .fill)
                                                .frame(width: 68, height: 68)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(DFColor.glassBorderGradient, lineWidth: 1.2))
                                                .shadow(color: Color.black.opacity(0.4), radius: 6, y: 3)

                                            Image(systemName: state.localStore.isFavoriteActor(actor.name) ? "heart.fill" : "heart")
                                                .font(.caption2)
                                                .foregroundStyle(state.localStore.isFavoriteActor(actor.name) ? .red : DFColor.textMuted)
                                                .padding(4)
                                                .background(DFColor.bg)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                                        }
                                        Text(actor.name)
                                            .font(DFFont.small())
                                            .foregroundStyle(DFColor.text)
                                            .lineLimit(1)
                                            .frame(width: 76)
                                        if !actor.character.isEmpty {
                                            Text(actor.character)
                                                .font(DFFont.small())
                                                .foregroundStyle(DFColor.textMuted)
                                                .lineLimit(1)
                                                .frame(width: 76)
                                        }
                                    }
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
}

@Observable
final class MovieDetailViewModel {
    var movie: Movie?
    var episodeServers: [EpisodeServer] = []
    var selectedEpisodeServerIndex: Int = 0
    var description: String = ""
    var availableServers: [SourceServer] = []
    var selectedServer: SourceServer = .kkphim
    var currentEpisode: Episode?
    var isLoading = false
    var showFullDesc = false
    private var loadedSlug: String?

    var currentEpisodes: [Episode] {
        guard !episodeServers.isEmpty else { return [] }
        let idx = min(max(0, selectedEpisodeServerIndex), episodeServers.count - 1)
        return episodeServers[idx].items
    }

    func load(slug: String, token: String?) async {
        guard loadedSlug != slug else { return }
        loadedSlug = slug
        isLoading = true
        defer { isLoading = false }

        var mergedMovies: [String: Movie] = [:]
        var serverEpisodes: [String: [EpisodeServer]] = [:]
        var desc = ""

        await withTaskGroup(of: (SourceServer, Movie?, [EpisodeServer], String).self) { group in
            for server in SourceServer.allCases {
                group.addTask { [server] in
                    do {
                        let (m, eps, d) = try await SourceClient.detail(server: server, slug: slug)
                        return (server, m, eps, d)
                    } catch {
                        return (server, nil, [], "")
                    }
                }
            }
            for await (server, m, eps, d) in group {
                if let m {
                    mergedMovies[server.rawValue] = m
                    serverEpisodes[server.rawValue] = eps
                    if d.count > desc.count { desc = d }
                }
            }
        }

        let allServers = mergedMovies.keys.compactMap { SourceServer(rawValue: $0) }
        let primary = mergedMovies[SourceServer.kkphim.rawValue]
                    ?? mergedMovies[SourceServer.ophim.rawValue]
                    ?? mergedMovies.first?.value

        let bestTMDB = mergedMovies.values.compactMap(\.tmdb).first(where: { $0.scoreString != "N/A" })
                    ?? mergedMovies.values.compactMap(\.tmdb).first
        let bestIMDB = mergedMovies.values.compactMap(\.imdb).first(where: { $0.scoreString != "N/A" })
                    ?? mergedMovies.values.compactMap(\.imdb).first
        let bestActors = mergedMovies.values.compactMap(\.actor).first(where: { !$0.isEmpty })
        let bestDirectors = mergedMovies.values.compactMap(\.director).first(where: { !$0.isEmpty })

        if let primary {
            self.movie = Movie(
                slug: primary.slug, name: primary.name, originName: primary.originName,
                thumbURL: primary.thumbURL, posterURL: primary.posterURL,
                year: primary.year, type: primary.type,
                episodeCurrent: primary.episodeCurrent,
                quality: primary.quality, lang: primary.lang,
                category: primary.category, country: primary.country,
                actor: bestActors ?? primary.actor,
                director: bestDirectors ?? primary.director,
                tmdb: bestTMDB ?? primary.tmdb,
                imdb: bestIMDB ?? primary.imdb,
                server: allServers.first?.rawValue,
                sources: allServers.map(\.rawValue),
                serverSlugs: mergedMovies.mapValues { $0.slug }
            )
        }

        self.availableServers = allServers
        let defaultServer = allServers.first ?? .kkphim
        self.selectedServer = defaultServer
        self.episodeServers = serverEpisodes[defaultServer.rawValue] ?? []
        self.selectedEpisodeServerIndex = 0
        self.description = desc
    }

    func switchServer(_ server: SourceServer) {
        selectedServer = server
        guard let slug = movie?.slug else { return }
        Task { [server] in
            do {
                let (_, eps, desc) = try await SourceClient.detail(server: server, slug: slug)
                self.episodeServers = eps
                self.selectedEpisodeServerIndex = 0
                if desc.count > description.count { description = desc }
            } catch {
                self.episodeServers = []
                self.selectedEpisodeServerIndex = 0
            }
        }
    }
}

#Preview {
    NavigationStack {
        MovieDetailView(slug: "mai")
    }
    .environment(AppState())
}
