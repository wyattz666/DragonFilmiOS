import SwiftUI

enum VIPBadgeStyle {
    case standard
    case compact
    case banner
}

struct VIPBadge: View {
    var title: String = "VIP MEMBER"
    var style: VIPBadgeStyle = .standard
    var icon: String = "crown.fill"

    var body: some View {
        switch style {
        case .compact:
            HStack(spacing: 3.5) {
                Image(systemName: icon)
                    .font(.system(size: 8.5, weight: .bold))
                Text(title)
                    .font(.system(size: 9.5, weight: .black, design: .rounded))
            }
            .foregroundStyle(Color(hex: 0x07080A))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0xFFE58F), Color(hex: 0xD4AF37), Color(hex: 0xAA7C11)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 0.6))
            .shadow(color: DFColor.gold.opacity(0.4), radius: 4)

        case .standard:
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(0.5)
            }
            .foregroundStyle(Color(hex: 0x07080A))
            .padding(.horizontal, 10)
            .padding(.vertical, 4.5)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0xFFE58F), Color(hex: 0xD4AF37), Color(hex: 0x996515)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.clear, Color.white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: DFColor.gold.opacity(0.45), radius: 6, y: 2)

        case .banner:
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(0.8)
            }
            .foregroundStyle(Color(hex: 0x07080A))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(DFColor.goldGradient)
            .clipShape(Capsule())
            .shadow(color: DFColor.gold.opacity(0.4), radius: 6)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        VIPBadge(title: "VIP", style: .compact)
        VIPBadge(title: "VIP MEMBER", style: .standard)
        VIPBadge(title: "VIP ADMIN", style: .standard)
        VIPBadge(title: "VIP MEMBER ACTIVATED", style: .banner)
    }
    .padding()
    .background(DFColor.bg)
}
