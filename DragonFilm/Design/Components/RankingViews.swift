import SwiftUI

/// A Netflix Top 10 row: rank number + wide poster art + title + type badge.
struct NetflixRankingRow: View {
    let item: NetflixItem
    let rank: Int

    var body: some View {
        HStack(spacing: DFSpacing.md) {
            rankBadge(rank)

            if let poster = item.tmdb?.posterURL ?? item.posterURL {
                RemoteImage(url: poster, contentMode: .fill)
                    .frame(width: 48, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: DFRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DFRadius.md)
                            .stroke(DFColor.glassBorderGradient, lineWidth: 0.7)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 4, y: 2)
            } else {
                RoundedRectangle(cornerRadius: DFRadius.md)
                    .fill(DFColor.bg3)
                    .frame(width: 48, height: 68)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(DFColor.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 5) {
                    Text(item.type == "tv" ? "TV Series" : "Phim Lẻ")
                        .font(DFFont.small())
                        .foregroundStyle(DFColor.textMuted)

                    if rank <= 3 {
                        Text("TOP \(rank)")
                            .font(DFFont.small())
                            .foregroundStyle(DFColor.crimson)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(DFColor.crimson.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
            }

            Spacer(minLength: 4)
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }
}

/// A TMDB weekly row: rank + poster + title (VN) + original title + TMDB score.
struct TMDBRankingRow: View {
    let item: TMDBWeeklyItem
    let rank: Int

    var body: some View {
        HStack(spacing: DFSpacing.md) {
            rankBadge(rank)

            if let poster = item.posterURL {
                RemoteImage(url: poster, contentMode: .fill)
                    .frame(width: 48, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: DFRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DFRadius.md)
                            .stroke(DFColor.glassBorderGradient, lineWidth: 0.7)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 4, y: 2)
            } else {
                RoundedRectangle(cornerRadius: DFRadius.md)
                    .fill(DFColor.bg3)
                    .frame(width: 48, height: 68)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(DFColor.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let orig = item.originalTitle, orig != item.title {
                    Text(orig)
                        .font(DFFont.small())
                        .foregroundStyle(DFColor.textMuted)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if let score = item.voteAverage, score > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                    Text(String(format: "%.1f", score))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(DFColor.gold)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(DFColor.gold.opacity(0.14))
                        .overlay(Capsule().stroke(DFColor.gold.opacity(0.3), lineWidth: 0.6))
                )
            }
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }
}

/// An AniList ranking row: rank + cover art + title + score badge.
struct AniListRankingRow: View {
    let item: AniListNormalized
    let rank: Int

    var body: some View {
        HStack(spacing: DFSpacing.md) {
            rankBadge(rank)

            if !item.coverURL.isEmpty {
                RemoteImage(url: item.coverURL, contentMode: .fill)
                    .frame(width: 48, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: DFRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DFRadius.md)
                            .stroke(DFColor.glassBorderGradient, lineWidth: 0.7)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 4, y: 2)
            } else {
                RoundedRectangle(cornerRadius: DFRadius.md)
                    .fill(DFColor.bg3)
                    .frame(width: 48, height: 68)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(DFColor.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if !item.altTitle.isEmpty && item.altTitle != item.title {
                    Text(item.altTitle)
                        .font(DFFont.small())
                        .foregroundStyle(DFColor.textMuted)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if item.score > 0 {
                Text("\(item.score)%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(DFColor.sage)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(DFColor.sage.opacity(0.14))
                            .overlay(Capsule().stroke(DFColor.sage.opacity(0.3), lineWidth: 0.6))
                    )
            }
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }
}

@ViewBuilder
private func rankBadge(_ rank: Int) -> some View {
    ZStack {
        if rank == 1 {
            Text("\(rank)")
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(DFColor.goldGradient)
                .shadow(color: DFColor.gold.opacity(0.5), radius: 6)
        } else if rank == 2 {
            Text("\(rank)")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [Color.white, Color(hex: 0xC0C7D5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        } else if rank == 3 {
            Text("\(rank)")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [Color(hex: 0xF6A060), Color(hex: 0xBA5A20)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        } else {
            Text("\(rank)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(DFColor.textMuted.opacity(0.8))
        }
    }
    .frame(width: 26, alignment: .center)
}

/// Full-width ranking panel with header + scrollable row list.
struct RankingPanel<Content: View>: View {
    let title: String
    let subtitle: String
    let badgeLabel: String
    let badgeColor: Color
    @ViewBuilder let rows: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: DFSpacing.md) {
            HStack(spacing: DFSpacing.md) {
                Text(badgeLabel.uppercased())
                    .font(DFFont.small())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(
                        Capsule()
                            .fill(badgeColor)
                            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.6))
                    )
                    .shadow(color: badgeColor.opacity(0.4), radius: 4, y: 1)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(DFFont.title2())
                        .foregroundStyle(DFColor.text)
                    Text(subtitle)
                        .font(DFFont.small())
                        .foregroundStyle(DFColor.textMuted)
                }
                Spacer()
            }
            .padding(.horizontal, DFSpacing.xxl)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: DFSpacing.lg) {
                    rows()
                }
                .padding(.horizontal, DFSpacing.xxl)
            }
        }
    }
}
