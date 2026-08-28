import SwiftUI

struct ScheduleView: View {
    @State private var viewModel = ScheduleViewModel()

    var body: some View {
        VStack(spacing: 0) {
            dayPicker

            if viewModel.isLoading && viewModel.movies.isEmpty {
                ScrollView {
                    LazyVStack(spacing: DFSpacing.lg) {
                        ForEach(0..<6, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: DFRadius.lg)
                                .fill(DFColor.bg3)
                                .frame(height: 96)
                                .shimmer()
                        }
                    }
                    .padding(.horizontal, DFSpacing.xxl)
                }
            } else if viewModel.movies.isEmpty {
                EmptyStateView(icon: "calendar",
                               title: "Chưa có lịch chiếu",
                               message: "Không tìm thấy phim nào cho ngày này.")
            } else {
                ScrollView {
                    LazyVStack(spacing: DFSpacing.lg) {
                        ForEach(viewModel.movies) { movie in
                            NavigationLink { MovieDetailView(slug: movie.slug) } label: {
                                ScheduleRow(movie: movie)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DFSpacing.xxl)
                    .padding(.bottom, DFSpacing.xxxl)
                }
                .refreshable { await viewModel.load(force: true) }
            }
        }
        .background(DFColor.bg)
        .navigationTitle("Lịch Chiếu")
        .task { await viewModel.load() }
    }

    private var dayPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DFSpacing.md) {
                ForEach(viewModel.days) { day in
                    Button { viewModel.selectedDay = day.date } label: {
                        VStack(spacing: 2) {
                            Text(day.weekdayShort)
                                .font(DFFont.small())
                            Text(day.dayNumber)
                                .font(DFFont.callout())
                        }
                        .foregroundStyle(viewModel.isSelected(day) ? DFColor.bg : DFColor.textDim)
                        .frame(width: 48, height: 52)
                        .background(viewModel.isSelected(day) ? DFColor.gold : DFColor.bg3)
                        .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: DFRadius.lg)
                                .stroke(day.isToday ? DFColor.borderStrong : .clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DFSpacing.xxl)
            .padding(.vertical, DFSpacing.lg)
        }
        .accessibilityLabel("Chọn ngày chiếu")
    }
}

private struct ScheduleRow: View {
    let movie: Movie

    var body: some View {
        HStack(spacing: DFSpacing.lg) {
            RemoteImage(url: movie.bestThumb, contentMode: .fill)
                .frame(width: 100, height: 62)
                .clipShape(RoundedRectangle(cornerRadius: DFRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: DFRadius.md)
                        .stroke(DFColor.border.opacity(0.35), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(movie.name)
                    .font(DFFont.callout())
                    .foregroundStyle(DFColor.text)
                    .lineLimit(2)
                HStack(spacing: DFSpacing.sm) {
                    if !movie.episodeCurrent.isEmpty {
                        Text(movie.episodeCurrent)
                            .font(DFFont.small())
                            .foregroundStyle(DFColor.gold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DFColor.gold.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: DFRadius.sm))
                    }
                    if !movie.yearString.isEmpty {
                        Text(movie.yearString)
                            .font(DFFont.small())
                            .foregroundStyle(DFColor.textMuted)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(DFColor.textMuted)
        }
        .padding(DFSpacing.lg)
        .background(DFColor.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DFRadius.lg)
                .stroke(DFColor.border.opacity(0.35), lineWidth: 0.5)
        )
    }
}

struct ScheduleDayItem: Identifiable {
    let date: Date
    var id: TimeInterval { date.timeIntervalSince1970 }
    var isToday: Bool { Calendar.current.isDateInToday(date) }

    var weekdayShort: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "vi_VN")
        f.dateFormat = "EEE"
        return f.string(from: date)
    }

    var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
}

/// The web schedule page aggregates upcoming releases from the movie sources.
/// There's no dedicated schedule endpoint, so this uses the "latest" listing —
/// the same data the web page falls back to.
@Observable
final class ScheduleViewModel {
    var movies: [Movie] = []
    var isLoading = false
    var selectedDay: Date = Date()

    var days: [ScheduleDayItem] {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        return (0..<14).compactMap { offset in
            cal.date(byAdding: .day, value: offset, to: start).map(ScheduleDayItem.init)
        }
    }

    func isSelected(_ day: ScheduleDayItem) -> Bool {
        Calendar.current.isDate(day.date, inSameDayAs: selectedDay)
    }

    func load(force: Bool = false) async {
        if !movies.isEmpty && !force { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let (result, _) = try await SourceClient.list(server: .kkphim, operation: "latest", page: 1)
            movies = result
        } catch {
            movies = []
        }
    }
}

#Preview {
    NavigationStack {
        ScheduleView()
    }
    .environment(AppState())
}
