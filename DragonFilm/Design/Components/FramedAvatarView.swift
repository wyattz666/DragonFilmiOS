import SwiftUI

struct FramedAvatarView: View {
    let avatarURL: String
    let username: String
    var frameId: String? = nil
    var size: CGFloat = 86

    var body: some View {
        ZStack {
            // Core circular avatar
            Group {
                if avatarURL.isEmpty {
                    Circle()
                        .fill(DFColor.bg3)
                        .overlay(
                            Text(String(username.prefix(1)).uppercased())
                                .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                                .foregroundStyle(DFColor.gold)
                        )
                } else {
                    AvatarImage(dataURL: avatarURL)
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(DFColor.glassBorderGradient, lineWidth: 1.5))
            .shadow(color: Color.black.opacity(0.45), radius: 6, y: 3)

            // VIP Frame overlay
            if let frameId, let vipFrame = VIPFrame.allFrames.first(where: { $0.id == frameId }) {
                Image(vipFrame.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 1.36, height: size * 1.36)
                    .allowsHitTesting(false)
                    .shadow(color: Color.black.opacity(0.3), radius: 4)
            }
        }
        .frame(width: size * 1.36, height: size * 1.36)
    }
}
