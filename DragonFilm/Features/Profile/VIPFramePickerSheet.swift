import SwiftUI

struct VIPFramePickerSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var selectedId: String?
    @State private var showAuthSheet = false

    private var isVIP: Bool {
        state.currentUser != nil
    }

    private let columns = [
        GridItem(.flexible(), spacing: DFSpacing.md),
        GridItem(.flexible(), spacing: DFSpacing.md)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DFSpacing.xl) {
                    // Header Banner
                    headerBanner

                    // Current Avatar Preview
                    currentPreviewCard

                    // Frames Grid
                    VStack(alignment: .leading, spacing: DFSpacing.md) {
                        Text("DANH SÁCH KHUNG VIP")
                            .font(DFFont.caption().bold())
                            .foregroundStyle(DFColor.gold)
                            .padding(.horizontal, DFSpacing.xs)

                        LazyVGrid(columns: columns, spacing: DFSpacing.lg) {
                            // Option: No Frame
                            noFrameCard

                            // All 9 VIP Frames
                            ForEach(VIPFrame.allFrames) { frame in
                                frameCard(frame)
                            }
                        }
                    }
                }
                .padding(DFSpacing.xl)
            }
            .background(DFColor.bg)
            .navigationTitle("Khung Avatar VIP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                        .foregroundStyle(DFColor.gold)
                }
            }
            .sheet(isPresented: $showAuthSheet) { AuthSheet() }
            .onAppear {
                selectedId = state.localStore.selectedVIPFrame()
            }
        }
    }

    private var headerBanner: some View {
        HStack(spacing: DFSpacing.md) {
            VIPBadge(title: "VIP EXCLUSIVE", style: .standard)
            Spacer()
            if isVIP {
                Text("Đã Kích Hoạt")
                    .font(DFFont.small().bold())
                    .foregroundStyle(DFColor.gold)
            } else {
                Text("Yêu Cầu Đăng Nhập")
                    .font(DFFont.small())
                    .foregroundStyle(DFColor.textMuted)
            }
        }
        .padding(DFSpacing.lg)
        .glassCard(cornerRadius: DFRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DFRadius.lg)
                .stroke(DFColor.gold.opacity(0.35), lineWidth: 0.8)
        )
    }

    private var currentPreviewCard: some View {
        VStack(spacing: DFSpacing.md) {
            let avatarURL = state.currentUser?.avatarURL ?? ""
            let username = state.currentUser?.username ?? "Khách"

            FramedAvatarView(
                avatarURL: avatarURL,
                username: username,
                frameId: selectedId,
                size: 96
            )

            VStack(spacing: 3) {
                Text(username)
                    .font(DFFont.headline())
                    .foregroundStyle(DFColor.text)

                if let selectedId, let current = VIPFrame.allFrames.first(where: { $0.id == selectedId }) {
                    Text("Khung: \(current.name)")
                        .font(DFFont.small().bold())
                        .foregroundStyle(DFColor.gold)
                } else {
                    Text("Khung mặc định (Không áp dụng)")
                        .font(DFFont.small())
                        .foregroundStyle(DFColor.textMuted)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DFSpacing.xl)
        .glassCard(cornerRadius: DFRadius.xl)
    }

    private var noFrameCard: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedId = nil
            state.localStore.setVIPFrame(nil)
        } label: {
            VStack(spacing: DFSpacing.md) {
                Circle()
                    .stroke(selectedId == nil ? DFColor.gold : DFColor.border.opacity(0.5), lineWidth: selectedId == nil ? 2 : 1)
                    .frame(width: 68, height: 68)
                    .overlay(
                        Image(systemName: "slash.circle")
                            .font(.system(size: 26))
                            .foregroundStyle(selectedId == nil ? DFColor.gold : DFColor.textMuted)
                    )

                VStack(spacing: 2) {
                    Text("Mặc định")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(selectedId == nil ? DFColor.gold : DFColor.text)
                    Text("Không dùng khung")
                        .font(DFFont.small())
                        .foregroundStyle(DFColor.textMuted)
                }

                if selectedId == nil {
                    Text("Đang dùng")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: 0x07080A))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(DFColor.goldGradient)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(DFSpacing.lg)
            .glassCard(cornerRadius: DFRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: DFRadius.lg)
                    .stroke(selectedId == nil ? DFColor.gold : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func frameCard(_ frame: VIPFrame) -> some View {
        let isSelected = (selectedId == frame.id)

        return Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if isVIP {
                selectedId = frame.id
                state.localStore.setVIPFrame(frame.id)
            } else {
                showAuthSheet = true
            }
        } label: {
            VStack(spacing: DFSpacing.md) {
                ZStack {
                    Circle()
                        .fill(DFColor.bg3)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Text(String((state.currentUser?.username ?? "VIP").prefix(1)).uppercased())
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(DFColor.gold.opacity(0.8))
                        )

                    Image(frame.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 76, height: 76)
                }
                .frame(width: 76, height: 76)

                VStack(spacing: 2) {
                    Text(frame.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isSelected ? DFColor.gold : DFColor.text)
                        .lineLimit(1)
                    Text(frame.description)
                        .font(DFFont.small())
                        .foregroundStyle(DFColor.textMuted)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }

                if isSelected {
                    Text("Đang dùng")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: 0x07080A))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(DFColor.goldGradient)
                        .clipShape(Capsule())
                } else if !isVIP {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                        Text("Khóa VIP")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(DFColor.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(DFColor.gold.opacity(0.15))
                    .clipShape(Capsule())
                } else {
                    Text("Chọn khung")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DFColor.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(DFSpacing.lg)
            .glassCard(cornerRadius: DFRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: DFRadius.lg)
                    .stroke(isSelected ? DFColor.gold : (isVIP ? Color.clear : DFColor.gold.opacity(0.2)), lineWidth: isSelected ? 1.5 : 0.8)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VIPFramePickerSheet()
        .environment(AppState())
}
