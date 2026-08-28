import SwiftUI

/// Shared between the Home feed (`movieKey = "dragonfilm_homepage"`) and movie
/// pages. Polls every 15s to mirror the web's "live" feel — the backend has no
/// websocket.
struct CommentSection: View {
    let movieKey: String
    let movieName: String
    var title: String = "Bình luận"

    @Environment(AppState.self) private var state
    @State private var comments: [Comment] = []
    @State private var draft = ""
    @State private var isSending = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DFSpacing.lg) {
            HStack {
                SectionHeader(title: title)
                Spacer()
                HStack(spacing: 5) {
                    Circle()
                        .fill(DFColor.liveGreen)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(DFFont.small())
                        .foregroundStyle(DFColor.liveGreen)
                }
                .padding(.trailing, DFSpacing.xxl)
            }

            composer

            if comments.isEmpty {
                Text("Chưa có bình luận.")
                    .font(DFFont.body())
                    .foregroundStyle(DFColor.textMuted)
                    .padding(.horizontal, DFSpacing.xxl)
                    .padding(.vertical, DFSpacing.xl)
            } else {
                VStack(spacing: DFSpacing.lg) {
                    ForEach(comments) { comment in
                        CommentRow(comment: comment,
                                   canDelete: state.currentUser?.isAdmin == true) {
                            Task { await delete(comment) }
                        }
                    }
                }
                .padding(.horizontal, DFSpacing.xxl)
            }
        }
        .task { await startPolling() }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: DFSpacing.md) {
            if state.isLoggedIn {
                TextField("Chia sẻ cảm nhận về phim...", text: $draft, axis: .vertical)
                    .font(DFFont.body())
                    .foregroundStyle(DFColor.text)
                    .lineLimit(1...4)
                    .padding(DFSpacing.lg)
                    .background(DFColor.bg3)
                    .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))

                HStack {
                    Text("\(draft.count)/500")
                        .font(DFFont.small())
                        .foregroundStyle(draft.count > 500 ? .red : DFColor.textMuted)
                    Spacer()
                    Button { Task { await send() } } label: {
                        Text("Gửi")
                            .font(DFFont.caption())
                            .foregroundStyle(DFColor.bg)
                            .padding(.horizontal, DFSpacing.xxl)
                            .padding(.vertical, DFSpacing.md)
                            .background(canSend ? DFColor.gold : DFColor.goldDim.opacity(0.4))
                            .clipShape(Capsule())
                    }
                    .disabled(!canSend || isSending)
                }
            } else {
                Text("Đăng nhập để bình luận.")
                    .font(DFFont.caption())
                    .foregroundStyle(DFColor.textMuted)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(DFFont.small())
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, DFSpacing.xxl)
    }

    private var canSend: Bool {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 500
    }

    // MARK: - Networking

    private func startPolling() async {
        await load()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(15))
            guard !Task.isCancelled else { return }
            await load()
        }
    }

    private func load() async {
        do {
            let response: CommentListEnvelope = try await APIClient.shared.get(
                "/api/comments", query: ["movieKey": movieKey]
            )
            comments = response.comments
        } catch {}
    }

    private func send() async {
        guard let token = state.auth.token else { return }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        do {
            let body: [String: Any] = [
                "movieKey": movieKey,
                "text": text,
                "movieName": movieName
            ]
            let _: CommentCreateEnvelope = try await APIClient.shared.post(
                "/api/comments", body: body, token: token
            )
            draft = ""
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ comment: Comment) async {
        guard let token = state.auth.token else { return }
        do {
            let _: OKEnvelope = try await APIClient.shared.delete(
                "/api/comments", body: ["id": comment.id], token: token
            )
            comments.removeAll { $0.id == comment.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct CommentRow: View {
    let comment: Comment
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: DFSpacing.lg) {
            avatar
                .frame(width: 36, height: 36)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: DFSpacing.xs) {
                HStack(spacing: DFSpacing.sm) {
                    Text(comment.user.username)
                        .font(DFFont.caption())
                        .foregroundStyle(DFColor.text)
                    if comment.user.isAdmin {
                        Badge(text: "Admin")
                    }
                    Spacer()
                    if canDelete {
                        Button(role: .destructive, action: onDelete) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(DFColor.textMuted)
                        }
                    }
                }
                Text(comment.body)
                    .font(DFFont.body())
                    .foregroundStyle(DFColor.textDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DFSpacing.lg)
        .background(DFColor.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
    }

    @ViewBuilder
    private var avatar: some View {
        if let url = comment.user.avatarURL, url.hasPrefix("data:") {
            AvatarImage(dataURL: url)
        } else {
            Circle()
                .fill(DFColor.bg3)
                .overlay(
                    Text(String(comment.user.username.prefix(1)).uppercased())
                        .font(DFFont.caption())
                        .foregroundStyle(DFColor.gold)
                )
        }
    }
}

private struct CommentListEnvelope: Decodable {
    let ok: Bool
    let comments: [Comment]
}

private struct CommentCreateEnvelope: Decodable {
    let ok: Bool
    let comment: Comment
}

private struct OKEnvelope: Decodable {
    let ok: Bool
}
