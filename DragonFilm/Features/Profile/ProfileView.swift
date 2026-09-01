import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(AppState.self) private var state
    @State private var showAuthSheet = false
    @State private var showPasswordSheet = false
    @State private var showFrameSheet = false
    @State private var avatarItem: PhotosPickerItem?
    @State private var isUploading = false
    @State private var syncMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: DFSpacing.xxl) {
                if let user = state.currentUser {
                    accountCard(user)
                    vipPrivilegeCard
                    statsRow
                    actionsList
                } else {
                    guestCard
                    vipGuestPerksCard
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
        .sheet(isPresented: $showFrameSheet) { VIPFramePickerSheet() }
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
            let selectedFrame = state.localStore.selectedVIPFrame()

            ZStack(alignment: .bottomTrailing) {
                FramedAvatarView(
                    avatarURL: user.avatarURL,
                    username: user.username,
                    frameId: selectedFrame,
                    size: 88
                )

                PhotosPicker(selection: $avatarItem, matching: .images) {
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
                .disabled(isUploading)
                .offset(x: -4, y: -4)
            }

            VStack(spacing: 6) {
                Text(user.username)
                    .font(DFFont.title2())
                    .foregroundStyle(DFColor.text)

                if !user.email.isEmpty {
                    Text(user.email)
                        .font(DFFont.caption())
                        .foregroundStyle(DFColor.textMuted)
                }

                VIPBadge(
                    title: user.isAdmin ? "VIP ADMIN" : "VIP MEMBER",
                    style: .standard
                )
                .padding(.top, 4)
            }

            Button {
                showFrameSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                    Text("Đổi Khung Avatar VIP")
                        .font(DFFont.caption().bold())
                }
                .foregroundStyle(Color(hex: 0x07080A))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(DFColor.goldGradient)
                .clipShape(Capsule())
                .shadow(color: DFColor.gold.opacity(0.35), radius: 6, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DFSpacing.xxl)
        .glassCard(cornerRadius: DFRadius.xl)
    }

    private var vipPrivilegeCard: some View {
        VStack(alignment: .leading, spacing: DFSpacing.md) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(DFColor.gold)
                    Text("ĐẶC QUYỀN VIP MEMBER")
                        .font(DFFont.caption().bold())
                        .foregroundStyle(DFColor.gold)
                }
                Spacer()
                Text("VĨNH VIỄN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: 0x07080A))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(DFColor.goldGradient)
                    .clipShape(Capsule())
            }

            Divider().overlay(Color.white.opacity(0.08))

            VStack(alignment: .leading, spacing: 10) {
                vipFeatureItem(icon: "bolt.fill", title: "Máy chủ phát phim VIP siêu tốc", desc: "Không giới hạn băng thông, xem tức thì")
                vipFeatureItem(icon: "tv.fill", title: "Chất lượng hình ảnh 4K & Full HD", desc: "Âm thanh vòm và phụ đề chuẩn điện ảnh")
                vipFeatureItem(icon: "sparkles.rectangle.stack.fill", title: "9 Khung Avatar VIP Độc Quyền", desc: "Tự do lựa chọn và trang bị khung avatar phong cách")
                vipFeatureItem(icon: "icloud.fill", title: "Đồng bộ đám mây DragonSync", desc: "Tự động lưu lịch sử và danh sách yêu thích")
            }
        }
        .padding(DFSpacing.lg)
        .glassCard(cornerRadius: DFRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DFRadius.lg)
                .stroke(DFColor.gold.opacity(0.35), lineWidth: 0.8)
        )
    }

    private var vipGuestPerksCard: some View {
        VStack(alignment: .leading, spacing: DFSpacing.md) {
            HStack(spacing: 6) {
                VIPBadge(title: "VIP MEMBER", style: .compact)
                Text("Kích hoạt đặc quyền VIP miễn phí")
                    .font(DFFont.caption().bold())
                    .foregroundStyle(DFColor.gold)
            }

            VStack(alignment: .leading, spacing: 8) {
                vipFeatureItem(icon: "bolt.fill", title: "Trải nghiệm phim mượt mà", desc: "Tối ưu hóa kết nối đa server")
                vipFeatureItem(icon: "sparkles.rectangle.stack.fill", title: "Mở khóa 9 khung avatar VIP", desc: "Độc quyền cho thành viên đăng nhập")
                vipFeatureItem(icon: "icloud.fill", title: "Lưu lịch sử & xem sau", desc: "Đồng bộ tự động khi đăng nhập")
            }

            Button {
                showFrameSheet = true
            } label: {
                HStack {
                    Text("Xem Bộ Sưu Tập Khung VIP")
                        .font(DFFont.caption().bold())
                        .foregroundStyle(DFColor.gold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(DFColor.goldDim)
                }
                .padding(DFSpacing.md)
                .background(DFColor.gold.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: DFRadius.md))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(DFSpacing.lg)
        .glassCard(cornerRadius: DFRadius.lg)
    }

    private func vipFeatureItem(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(DFColor.gold)
                .frame(width: 22, height: 22)
                .background(DFColor.gold.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DFColor.text)
                Text(desc)
                    .font(DFFont.small())
                    .foregroundStyle(DFColor.textMuted)
            }
        }
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
            Text("Đăng nhập để nhận huy hiệu VIP MEMBER và đồng bộ đám mây giữa các thiết bị.")
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
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.2"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "3"
            Text("Phiên bản v\(version) (Build \(build))")
                .font(DFFont.small())
                .foregroundStyle(DFColor.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DFSpacing.md)
        .padding(.bottom, DFSpacing.xl)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environment(AppState())
}
