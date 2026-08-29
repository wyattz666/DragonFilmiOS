import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(AppState.self) private var state
    @State private var showAuthSheet = false
    @State private var showPasswordSheet = false
    @State private var avatarItem: PhotosPickerItem?
    @State private var isUploading = false
    @State private var syncMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: DFSpacing.xxl) {
                if let user = state.currentUser {
                    accountCard(user)
                    statsRow
                    actionsList
                } else {
                    guestCard
                }

                appVersionFooter
            }
            .padding(.horizontal, DFSpacing.xxl)
            .padding(.vertical, DFSpacing.xl)
        }
        .background(DFColor.bg)
        .navigationTitle("Thành viên")
        .sheet(isPresented: $showAuthSheet) { AuthSheet() }
        .sheet(isPresented: $showPasswordSheet) { ChangePasswordSheet() }
        .onChange(of: avatarItem) { _, item in
            guard let item else { return }
            Task { await uploadAvatar(item) }
        }
        .task { await state.loadProfile() }
    }

    private func uploadAvatar(_ item: PhotosPickerItem) async {
        isUploading = true
        defer { isUploading = false }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let jpeg = resized(image).jpegData(compressionQuality: 0.72)
        else { return }
        do {
            try await state.uploadAvatar(imageData: jpeg)
            syncMessage = "Đã cập nhật ảnh đại diện."
        } catch {
            syncMessage = error.localizedDescription
        }
    }

    /// The endpoint caps the base64 payload at ~220 KB, so downscale first.
    private func resized(_ image: UIImage, maxDimension: CGFloat = 320) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func accountCard(_ user: User) -> some View {
        VStack(spacing: DFSpacing.lg) {
            PhotosPicker(selection: $avatarItem, matching: .images) {
                Group {
                    if user.avatarURL.isEmpty {
                        Circle()
                            .fill(DFColor.bg3)
                            .overlay(
                                Text(String(user.username.prefix(1)).uppercased())
                                    .font(DFFont.largeTitle())
                                    .foregroundStyle(DFColor.gold)
                            )
                    } else {
                        AvatarImage(dataURL: user.avatarURL)
                    }
                }
                .frame(width: 92, height: 92)
                .clipShape(Circle())
                .overlay(Circle().stroke(DFColor.glassBorderGradient, lineWidth: 1.5))
                .shadow(color: Color.black.opacity(0.5), radius: 8, y: 4)
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .fill(DFColor.goldGradient)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: 0x07080A))
                        )
                        .shadow(color: DFColor.gold.opacity(0.5), radius: 4)
                }
            }
            .disabled(isUploading)

            VStack(spacing: 4) {
                Text(user.username)
                    .font(DFFont.title2())
                    .foregroundStyle(DFColor.text)
                if !user.email.isEmpty {
                    Text(user.email)
                        .font(DFFont.caption())
                        .foregroundStyle(DFColor.textMuted)
                }
                if user.isAdmin {
                    Text("VIP ADMIN")
                        .font(DFFont.small())
                        .foregroundStyle(Color(hex: 0x07080A))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(DFColor.goldGradient)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DFSpacing.xxl)
        .glassCard(cornerRadius: DFRadius.xl)
    }

    private var guestCard: some View {
        VStack(spacing: DFSpacing.xl) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 56))
                .foregroundStyle(DFColor.gold)
                .shadow(color: DFColor.gold.opacity(0.3), radius: 8)
            Text("Chưa đăng nhập")
                .font(DFFont.headline())
                .foregroundStyle(DFColor.text)
            Text("Đăng nhập để đồng bộ lịch sử xem và thư viện phim giữa các thiết bị.")
                .font(DFFont.body())
                .foregroundStyle(DFColor.textDim)
                .multilineTextAlignment(.center)

            Button { showAuthSheet = true } label: {
                Text("Đăng Nhập Ngay")
                    .font(DFFont.headline())
                    .foregroundStyle(Color(hex: 0x07080A))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DFColor.goldGradient)
                    .clipShape(RoundedRectangle(cornerRadius: DFRadius.md))
                    .shadow(color: DFColor.gold.opacity(0.4), radius: 8, y: 3)
            }
        }
        .padding(DFSpacing.xxl)
        .glassCard(cornerRadius: DFRadius.xl)
    }

    private var statsRow: some View {
        HStack(spacing: DFSpacing.md) {
            statTile("Đã xem", "\(state.localStore.history().count)")
            statTile("Xem sau", "\(state.localStore.watchLater().count)")
            statTile("Yêu thích", "\(state.localStore.likedMovies().count)")
        }
    }

    private func statTile(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(DFColor.gold)
            Text(label)
                .font(DFFont.small())
                .foregroundStyle(DFColor.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DFSpacing.lg)
        .glassCard(cornerRadius: DFRadius.md)
    }

    private var actionsList: some View {
        VStack(spacing: 0) {
            actionRow("Đồng bộ dữ liệu", icon: "arrow.triangle.2.circlepath") {
                Task {
                    await state.cloudSync.sync()
                    syncMessage = "Đã đồng bộ với máy chủ."
                }
            }
            Divider().overlay(Color.white.opacity(0.08))
            actionRow("Đổi mật khẩu", icon: "lock") { showPasswordSheet = true }
            Divider().overlay(Color.white.opacity(0.08))
            actionRow("Đăng xuất", icon: "arrow.right.square", destructive: true) {
                state.logout()
            }

            if let syncMessage {
                Text(syncMessage)
                    .font(DFFont.small())
                    .foregroundStyle(DFColor.sage)
                    .padding(.horizontal, DFSpacing.lg)
                    .padding(.bottom, DFSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .glassCard(cornerRadius: DFRadius.lg)
    }

    private func actionRow(_ title: String, icon: String, destructive: Bool = false,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DFSpacing.lg) {
                Image(systemName: icon)
                    .foregroundStyle(destructive ? .red : DFColor.goldDim)
                    .frame(width: 22)
                Text(title)
                    .font(DFFont.body())
                    .foregroundStyle(destructive ? .red : DFColor.text)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(DFColor.textMuted)
            }
            .padding(DFSpacing.lg)
        }
        .buttonStyle(.plain)
    }

    private var appVersionFooter: some View {
        VStack(spacing: 4) {
            Text("DragonFilm iOS")
                .font(DFFont.caption().bold())
                .foregroundStyle(DFColor.goldDim)
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.1"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "2"
            Text("Phiên bản v\(version) (Build \(build))")
                .font(DFFont.small())
                .foregroundStyle(DFColor.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DFSpacing.md)
        .padding(.bottom, DFSpacing.xl)
    }
}

/// Avatars come back as base64 data URLs, which `RemoteImage` can't fetch.
struct AvatarImage: View {
    let dataURL: String

    var body: some View {
        if let image = decoded {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Circle().fill(DFColor.bg3)
        }
    }

    private var decoded: UIImage? {
        guard let comma = dataURL.firstIndex(of: ","),
              let data = Data(base64Encoded: String(dataURL[dataURL.index(after: comma)...]))
        else { return nil }
        return UIImage(data: data)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environment(AppState())
}
