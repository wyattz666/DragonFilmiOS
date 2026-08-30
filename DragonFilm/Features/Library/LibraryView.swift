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
                case .watchLater:
                    movieGrid(state.localStore.watchLater(),
                              emptyTitle: "Chưa có phim xem sau",
                              emptyMessage: "Lưu phim từ trang chi tiết để xem lại sau.")
                case .liked:
                    movieGrid(state.localStore.likedMovies(),
                              emptyTitle: "Chưa có phim yêu thích",
                              emptyMessage: "Bấm biểu tượng Yêu thích ở trang phim để thêm vào đây.")
                case .actors:
                    actorList
                }
            }
            .id(refreshToken)
        }
        .background(DFColor.bg)
        .navigationTitle("Thư Viện")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if hasContent {
                    Button("Xóa Tất Cả", role: .destructive) {
                        showClearConfirmation = true
                    }
                    .font(DFFont.caption())
                    .foregroundStyle(DFColor.goldDim)
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

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DFSpacing.md) {
                ForEach(LibraryTab.allCases) { item in
                    Button { withAnimation(.easeOut(duration: 0.2)) { tab = item } } label: {
                        Text(item.title)
                            .font(DFFont.caption().bold())
                            .foregroundStyle(tab == item ? Color(hex: 0x07080A) : DFColor.textDim)
                            .padding(.horizontal, DFSpacing.xl)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(tab == item ? DFColor.gold : Color.white.opacity(0.08))
                                    .overlay(
                                        Capsule()
                                            .stroke(tab == item ? DFColor.gold : Color.white.opacity(0.12), lineWidth: 0.6)
                                    )
                            )
                            .shadow(color: tab == item ? DFColor.gold.opacity(0.35) : .clear, radius: 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DFSpacing.xxl)
            .padding(.vertical, DFSpacing.md)
        }
    }

    private var historyList: some View {
        let items = state.localStore.history()
        return Group {
            if items.isEmpty {
                EmptyStateView(icon: "clock.arrow.circlepath",
                               title: "Chưa có lịch sử xem",
                               message: "Những phim bạn xem sẽ xuất hiện ở đây.")
                    .frame(minHeight: 360)
            } else {
                LazyVStack(spacing: DFSpacing.md) {
                    ForEach(items) { item in
                        NavigationLink { MovieDetailView(slug: item.slug) } label: {
                            HistoryRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DFSpacing.xxl)
                .padding(.bottom, DFSpacing.xxxl)
            }
        }
    }

    private func movieGrid(_ movies: [Movie], emptyTitle: String, emptyMessage: String) -> some View {
        Group {
            if movies.isEmpty {
                EmptyStateView(icon: "bookmark", title: emptyTitle, message: emptyMessage)
                    .frame(minHeight: 360)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DFSpacing.md), count: 3),
                          spacing: DFSpacing.xl) {
                    ForEach(movies) { movie in
                        NavigationLink { MovieDetailView(slug: movie.slug) } label: {
                            PosterCard(imageURL: movie.bestPoster, title: movie.name,
                                       subtitle: movie.yearString, badge: nil, width: posterWidth)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DFSpacing.xxl)
                .padding(.bottom, DFSpacing.xxxl)
            }
        }
    }

    private var actorList: some View {
        let actors = state.localStore.favoriteActors()
        return Group {
            if actors.isEmpty {
                EmptyStateView(icon: "person.2",
                               title: "Chưa có diễn viên yêu thích",
                               message: "Bấm vào diễn viên ở trang phim để lưu.")
                    .frame(minHeight: 360)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DFSpacing.xl), count: 3),
                          spacing: DFSpacing.xl) {
                    ForEach(actors) { actor in
                        VStack(spacing: DFSpacing.sm) {
                            RemoteImage(url: actor.profileURL, contentMode: .fill)
                                .frame(width: 76, height: 76)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(DFColor.glassBorderGradient, lineWidth: 1.2))
                                .shadow(color: Color.black.opacity(0.4), radius: 6, y: 3)
                            Text(actor.name)
                                .font(DFFont.caption())
                                .foregroundStyle(DFColor.text)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, DFSpacing.xxl)
                .padding(.bottom, DFSpacing.xxxl)
            }
        }
    }

    private var posterWidth: CGFloat {
        (UIScreen.main.bounds.width - DFSpacing.xxl * 2 - DFSpacing.md * 2) / 3
    }

    private var hasContent: Bool {
        switch tab {
        case .history: return !state.localStore.history().isEmpty
        case .watchLater: return !state.localStore.watchLater().isEmpty
        case .liked: return !state.localStore.likedMovies().isEmpty
        case .actors: return !state.localStore.favoriteActors().isEmpty
        }
    }

    private func clearCurrentTab() {
        state.localStore.clear(tab)
        refreshToken += 1
        Task { await state.cloudSync.sync() }
    }
}

enum LibraryTab: String, CaseIterable, Identifiable {
    case history, watchLater, liked, actors
    var id: String { rawValue }
    var title: String {
        switch self {
        case .history: return "Lịch sử xem"
        case .watchLater: return "Phim xem sau"
        case .liked: return "Phim yêu thích"
        case .actors: return "Diễn viên"
        }
    }
}

private struct HistoryRow: View {
    let item: HistoryItem

    var body: some View {
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
        .padding(DFSpacing.md)
        .glassCard(cornerRadius: DFRadius.lg)
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
