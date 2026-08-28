import SwiftUI

struct PosterCard: View {
    let imageURL: String?
    let title: String
    var subtitle: String? = nil
    var badge: String? = nil
    var width: CGFloat = 124

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ZStack(alignment: .topTrailing) {
                // Poster Image Container
                ZStack(alignment: .bottom) {
                    RemoteImage(url: imageURL, contentMode: .fill)
                        .frame(width: width, height: width * 1.5)
                        .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: DFRadius.lg)
                                .stroke(DFColor.glassBorderGradient, lineWidth: 0.8)
                        )
                        .shadow(color: Color.black.opacity(0.55), radius: 8, x: 0, y: 4)

                    // Subtle bottom gradient inside poster
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.45)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
                    .frame(height: 40)
                }

                // Glass Badge
                if let badge, !badge.isEmpty {
                    Text(cleanBadge(badge))
                        .font(DFFont.small())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(badgeBgColor.opacity(0.88))
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.6)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 3, y: 1)
                        .padding(6)
                }
            }

            // Title & Subtitle Metadata
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(DFColor.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(width: width, height: 34, alignment: .topLeading)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(DFFont.caption())
                        .foregroundStyle(DFColor.textMuted)
                        .lineLimit(1)
                        .frame(width: width, alignment: .leading)
                }
            }
        }
    }

    private func cleanBadge(_ text: String) -> String {
        text.replacingOccurrences(of: "Tập ", with: "T.")
            .uppercased()
    }

    private var badgeBgColor: Color {
        let b = badge?.lowercased() ?? ""
        if b.contains("hoạt hình") || b.contains("anime") { return DFColor.sage }
        if b.contains("hoàn tất") || b.contains("full") { return DFColor.goldDim }
        if b.contains("lồng tiếng") { return DFColor.purple }
        if b.contains("thuyết minh") { return DFColor.amber }
        return DFColor.steel
    }
}

/// 16:9 Cinema Card for "Tiếp tục xem" (Continue Watching)
struct ContinueWatchingCard: View {
    let item: HistoryItem
    var width: CGFloat = 220

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .center) {
                // Backdrop 16:9 Image
                RemoteImage(url: item.posterURL, contentMode: .fill)
                    .frame(width: width, height: width * 0.56)
                    .clipShape(RoundedRectangle(cornerRadius: DFRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DFRadius.md)
                            .stroke(DFColor.glassBorderGradient, lineWidth: 0.8)
                    )
                    .overlay(Color.black.opacity(0.28))
                    .shadow(color: Color.black.opacity(0.5), radius: 8, y: 4)

                // Glowing Play Icon
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(DFColor.gold)
                    .shadow(color: DFColor.gold.opacity(0.6), radius: 10)

                // Progress Bar at Bottom
                VStack {
                    Spacer()
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.25))
                            .frame(height: 3.5)
                        Rectangle()
                            .fill(DFColor.goldGradient)
                            .frame(width: width * 0.55, height: 3.5)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .frame(width: width, height: width * 0.56)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(DFColor.text)
                    .lineLimit(1)
                    .frame(width: width, alignment: .leading)

                HStack(spacing: 4) {
                    Text(item.episodeName)
                        .font(DFFont.caption())
                        .foregroundStyle(DFColor.gold)
                    Text("•")
                        .font(DFFont.small())
                        .foregroundStyle(DFColor.textMuted)
                    Text(SourceServer(rawValue: item.server)?.displayName ?? item.server.uppercased())
                        .font(DFFont.small())
                        .foregroundStyle(DFColor.textMuted)
                }
                .frame(width: width, alignment: .leading)
            }
        }
    }
}

struct PosterCardSkeleton: View {
    var width: CGFloat = 124

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            RoundedRectangle(cornerRadius: DFRadius.lg)
                .fill(DFColor.bg3)
                .frame(width: width, height: width * 1.5)
                .shimmer()

            RoundedRectangle(cornerRadius: DFRadius.sm)
                .fill(DFColor.bg3)
                .frame(width: width * 0.85, height: 12)
                .shimmer()

            RoundedRectangle(cornerRadius: DFRadius.sm)
                .fill(DFColor.bg3)
                .frame(width: width * 0.5, height: 10)
                .shimmer()
        }
    }
}

#Preview {
    ZStack {
        DFColor.bg.ignoresSafeArea()
        HStack(spacing: 16) {
            PosterCard(imageURL: nil, title: "Nghệ Thuật Săn Quỷ", subtitle: "2024", badge: "Tập 12")
            PosterCard(imageURL: nil, title: "One Piece Đảo Hải Tặc", subtitle: "Anime", badge: "Vietsub")
        }
    }
}
