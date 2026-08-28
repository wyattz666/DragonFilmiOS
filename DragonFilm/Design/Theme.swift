import SwiftUI

enum DFColor {
    // Deep Cinema Obsidian Backgrounds
    static let bg          = Color(hex: 0x07080A)
    static let bg2         = Color(hex: 0x0E1015)
    static let bg3         = Color(hex: 0x151922)
    static let bg4         = Color(hex: 0x1F2430)
    static let cardBg      = Color(hex: 0x11141A, alpha: 0.85)
    static let surface     = Color(hex: 0x161B24, alpha: 0.75)
    static let glass       = Color.white.opacity(0.06)

    // Cinematic Accents
    static let gold        = Color(hex: 0xF5C518)
    static let goldLight   = Color(hex: 0xFFE082)
    static let goldDim     = Color(hex: 0xC59E27)
    static let amber       = Color(hex: 0xFF6B00)
    static let crimson     = Color(hex: 0xE50914)
    static let sage        = Color(hex: 0x10B981)
    static let steel       = Color(hex: 0x38BDF8)
    static let purple      = Color(hex: 0xA855F7)

    // Text hierarchy
    static let text        = Color(hex: 0xF9FAFB)
    static let textDim     = Color(hex: 0xD1D5DB)
    static let textMuted   = Color(hex: 0x828997)

    // Metallic & Glass Borders
    static let border       = Color(hex: 0xF5C518, alpha: 0.22)
    static let borderStrong = Color(hex: 0xF5C518, alpha: 0.55)
    static let glassBorder  = Color.white.opacity(0.12)

    static let liveGreen    = Color(hex: 0x10B981)

    // Gradients
    static let goldGradient = LinearGradient(
        colors: [Color(hex: 0xFFE082), Color(hex: 0xF5C518), Color(hex: 0xD49E10)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let fireGradient = LinearGradient(
        colors: [Color(hex: 0xFF8A00), Color(hex: 0xE52E71)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassBorderGradient = LinearGradient(
        stops: [
            .init(color: Color.white.opacity(0.35), location: 0),
            .init(color: Color(hex: 0xF5C518, alpha: 0.3), location: 0.5),
            .init(color: Color.white.opacity(0.08), location: 1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum DFRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 10
    static let lg: CGFloat = 14
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 26
    static let pill: CGFloat = 999
}

enum DFSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 20
    static let xxxl: CGFloat = 24
    static let sectionH: CGFloat = 36
}

enum DFFont {
    static func heroTitle() -> Font  { .system(size: 26, weight: .heavy, design: .rounded) }
    static func largeTitle() -> Font { .system(size: 24, weight: .heavy, design: .rounded) }
    static func title() -> Font      { .system(size: 20, weight: .bold, design: .rounded) }
    static func title2() -> Font     { .system(size: 18, weight: .bold, design: .rounded) }
    static func headline() -> Font   { .system(size: 16, weight: .semibold, design: .rounded) }
    static func body() -> Font       { .system(size: 14, weight: .regular) }
    static func callout() -> Font    { .system(size: 13, weight: .medium) }
    static func caption() -> Font    { .system(size: 11, weight: .semibold) }
    static func small() -> Font      { .system(size: 9.5, weight: .bold) }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = DFRadius.lg) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(DFColor.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(DFColor.glassBorderGradient, lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.45), radius: 10, y: 5)
        )
    }

    func cinemaShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.6), radius: 12, x: 0, y: 6)
    }

    func goldGlow(radius: CGFloat = 12) -> some View {
        self.shadow(color: DFColor.gold.opacity(0.35), radius: radius, x: 0, y: 0)
    }
}
