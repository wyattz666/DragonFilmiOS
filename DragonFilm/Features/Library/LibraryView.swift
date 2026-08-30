import SwiftUI

struct LibraryView: View {
    @Environment(AppState.self) private var state
    @State private var tab: LibraryTab = .history
    @State private var refreshToken = 0
    @State private var showClearConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            tabBar

            ScrollView {
                switch tab {
                case .history:
                    historyList
                case .liked:
                    movieGrid(state.localStore.likedMovies(),
                              emptyIcon: "heart.slash",
                              emptyTitle: "Chưa có phim yêu thích",
                              emptyMessage: "Bấm biểu tượng trái tim ở trang chi tiết phim để lưu vào danh sách yêu thích.")
                case .watchLater:
                    movieGrid(state.localStore.watchLater(),
                              emptyIcon: "bookmark.slash",
                              emptyTitle: "Chưa có phim xem sau",
                              emptyMessage: "Bấm nút 'Xem sau' ở trang chi tiết phim để lưu lại xem khi rảnh.")
                case .actors:
                    actorList
                }
            }
            .id(refreshToken)
        }
        .background(DFColor.bg)
        .navigationTitle("Thư Viện")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if hasContent {
                    Button {
                        showClearConfirmation = true
                    } label: {
                        Text("Xóa")
                            .font(DFFont.caption().bold())
                            .foregroundStyle(DFColor.goldDim)
                    }
                }
            }
        }
        .confirmationDialog("Xác nhận xóa?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
            Button("Xóa toàn bộ \(tab.title.lowercased())", role: .destructive) {
                clearCurrentTab()
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Dữ liệu đã xóa sẽ không thể phục hồi.")
        }
        .onAppear {
            Task { await state.cloudSync.sync() }
        }
        .refreshable {
            await state.cloudSync.sync()
        }
        .task { await state.cloudSync.sync() }
    }

    // MARK: - Tab Bar with Icons & Counts

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LibraryTab.allCases) { item in
                    let isSelected = tab == item
                    let count = countFor(item)

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeOut(duration: 0.2)) { tab = item }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: item.icon)
                                .font(.system(size: 13, weight: .bold))

                            Text(item.title)
                                .font(DFFont.caption().bold())

                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(isSelected ? Color(hex: 0x07080A).opacity(0.2) : Color.white.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                        .foregroundStyle(isSelected ? Color(hex: 0x07080A) : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? DFColor.gold : Color.white.opacity(0.08))
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.14), lineWidth: 0.8)
                                )
                        )
                        .shadow(color: isSelected ? DFColor.gold.opacity(0.35) : .clear, radius: 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DFSpacing.xxl)
            .padding(.vertical, 6)
        }
        .frame(height: 52)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - History List

    private var historyList: some View {
        let items = state.localStore.history()
        return Group {
            if items.isEmpty {
                EmptyStateView(icon: "clock.arrow.circlepath",
                               title: "Chưa có lịch sử xem",
                               message: "Những bộ phim bạn vừa xem sẽ tự động lưu lại ở đây.")
                    .frame(minHeight: 360)
            } else {
                LazyVStack(spacing: DFSpacing.md) {
                    ForEach(items) { item in
                        HistoryRow(item: item) {
                            withAnimation(.easeOut(duration: 0.25)) {
                                state.localStore.removeFromHistory(slug: item.slug)
                                refreshToken += 1
                            }
                            Task { await state.cloudSync.push() }
                        }
                    }
                }
                .padding(.horizontal, DFSpacing.xxl)
                .padding(.top, DFSpacing.sm)
                .padding(.bottom, DFSpacing.xxxl)
            }
        }
    }

    // MARK: - Movie Grid (Liked & Watch Later)

    private func movieGrid(_ movies: [Movie], emptyIcon: String, emptyTitle: String, emptyMessage: String) -> some View {
        Group {
            if movies.isEmpty {
                EmptyStateView(icon: emptyIcon, title: emptyTitle, message: emptyMessage)
                    .frame(minHeight: 360)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DFSpacing.md), count: 3),
                          spacing: DFSpacing.xl) {
                    ForEach(movies) { movie in
                        NavigationLink { MovieDetailView(slug: movie.slug) } label: {
                            PosterCard(imageURL: movie.bestPoster, title: movie.name,
                                       subtitle: movie.yearString, badge: movie.episodeCurrent, width: posterWidth)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    if tab == .liked {
                                        state.localStore.removeFromLiked(slug: movie.slug)
                                    } else if tab == .watchLater {
                                        state.localStore.removeFromWatchLater(slug: movie.slug)
                                    }
                                    refreshToken += 1
                                }
                                Task { await state.cloudSync.push() }
                            } label: {
                                Label("Xóa khỏi danh sách", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, DFSpacing.xxl)
                .padding(.top, DFSpacing.sm)
                .padding(.bottom, DFSpacing.xxxl)
            }
        }
    }

    // MARK: - Favorite Actors List

    private var actorList: some View {
        let actors = state.localStore.favoriteActors()
        return Group {
            if actors.isEmpty {
                EmptyStateView(icon: "person.2",
                               title: "Chưa có diễn viên yêu thích",
                               message: "Bấm vào biểu tượng trái tim cạnh diễn viên ở trang chi tiết phim để thêm vào đây.")
                    .frame(minHeight: 360)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DFSpacing.lg), count: 3),
                          spacing: DFSpacing.xl) {
                    ForEach(actors) { actor in
                        NavigationLink {
                            SearchView(initialQuery: actor.name)
                        } label: {
                            VStack(spacing: DFSpacing.sm) {
                                RemoteImage(url: actor.profileURL, contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(DFColor.gold.opacity(0.6), lineWidth: 1.2))
                                    .shadow(color: Color.black.opacity(0.5), radius: 6, y: 3)

                                Text(actor.name)
                                    .font(DFFont.caption().bold())
                                    .foregroundStyle(DFColor.text)
                                    .lineLimit(1)
                                    .multilineTextAlignment(.center)

                                if !actor.character.isEmpty {
                                    Text(actor.character)
                                        .font(DFFont.small())
                                        .foregroundStyle(DFColor.textMuted)
                                        .lineLimit(1)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    state.localStore.removeFromActors(name: actor.name)
                                    refreshToken += 1
                                }
                                Task { await state.cloudSync.push() }
                            } label: {
                                Label("Bỏ yêu thích diễn viên", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, DFSpacing.xxl)
                .padding(.top, DFSpacing.sm)
                .padding(.bottom, DFSpacing.xxxl)
            }
        }
    }

    private var posterWidth: CGFloat {
        (UIScreen.main.bounds.width - DFSpacing.xxl * 2 - DFSpacing.md * 2) / 3
    }

    private func countFor(_ tab: LibraryTab) -> Int {
        switch tab {
        case .liked: return state.localStore.likedMovies().count
        case .watchLater: return state.localStore.watchLater().count
        case .history: return state.localStore.history().count
        case .actors: return state.localStore.favoriteActors().count
        }
    }

    private var hasContent: Bool {
        countFor(tab) > 0
    }

    private func clearCurrentTab() {
        state.localStore.clear(tab)
        refreshToken += 1
        Task { await state.cloudSync.push() }
    }
}

enum LibraryTab: String, CaseIterable, Identifiable {
    case history, liked, watchLater, actors
    var id: String { rawValue }

    var title: String {
        switch self {
        case .history: return "Lịch sử"
        case .liked: return "Phim yêu thích"
        case .watchLater: return "Phim xem sau"
        case .actors: return "Diễn viên yêu thích"
        }
    }

    var icon: String {
        switch self {
        case .history: return "clock.arrow.circlepath"
        case .liked: return "heart.fill"
        case .watchLater: return "bookmark.fill"
        case .actors: return "person.2.fill"
        }
    }
}

private struct HistoryRow: View {
    let item: HistoryItem
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: DFSpacing.md) {
            NavigationLink { MovieDetailView(slug: item.slug) } label: {
                HStack(spacing: DFSpacing.lg) {
                    RemoteImage(url: item.posterURL, contentMode: .fill)
                        .frame(width: 64, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: DFRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: DFRadius.md)
                                .stroke(DFColor.glassBorderGradient, lineWidth: 0.7)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(DFColor.text)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Text(item.episodeName)
                                .font(DFFont.caption().bold())
                                .foregroundStyle(DFColor.gold)

                            if item.progress > 0 {
                                Text("•")
                                    .font(DFFont.small())
                                    .foregroundStyle(DFColor.textMuted)
                                Text(item.progressPercentText)
                                    .font(DFFont.small().bold())
                                    .foregroundStyle(DFColor.goldDim)
                            }
                        }

                        Text(relativeWatchedAt)
                            .font(DFFont.small())
                            .foregroundStyle(DFColor.textMuted)
                    }

                    Spacer()

                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(DFColor.gold)
                        .shadow(color: DFColor.gold.opacity(0.4), radius: 6)
                }
            }
            .buttonStyle(.plain)

            if let onDelete {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DFColor.goldDim)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DFSpacing.md)
        .glassCard(cornerRadius: DFRadius.lg)
        .contextMenu {
            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Xóa khỏi lịch sử xem", systemImage: "trash")
                }
            }
        }
    }

    private var relativeWatchedAt: String {
        let date = Date(timeIntervalSince1970: item.watchedAt)
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "vi_VN")
        return f.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
    .environment(AppState())
}
