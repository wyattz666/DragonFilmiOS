import SwiftUI
import AuthenticationServices

struct AuthSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode = .login
    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @State private var showGoogleOAuth = false

    enum Mode { case login, register }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DFSpacing.xl) {
                    modeTabs

                    VStack(spacing: DFSpacing.lg) {
                        field("Tên tài khoản", text: $username, hint: mode == .register ? "Ít nhất 3 ký tự" : nil)
                        if mode == .register {
                            field("Email", text: $email, keyboard: .emailAddress)
                            field("Số điện thoại", text: $phone, keyboard: .phonePad)
                        }
                        secureField("Mật khẩu", text: $password, hint: mode == .register ? "Trên 6 ký tự" : nil)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(DFFont.caption())
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button { Task { await submit() } } label: {
                        Group {
                            if isSubmitting {
                                ProgressView().tint(DFColor.bg)
                            } else {
                                Text(mode == .login ? "Đăng Nhập" : "Tạo Tài Khoản")
                                    .font(DFFont.headline())
                            }
                        }
                        .foregroundStyle(DFColor.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DFSpacing.lg)
                        .background(canSubmit ? DFColor.gold : DFColor.goldDim.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
                    }
                    .disabled(!canSubmit || isSubmitting)

                    HStack(spacing: DFSpacing.lg) {
                        Rectangle().fill(DFColor.border).frame(height: 1)
                        Text("hoặc")
                            .font(DFFont.small())
                            .foregroundStyle(DFColor.textMuted)
                        Rectangle().fill(DFColor.border).frame(height: 1)
                    }

                    Button { showGoogleOAuth = true } label: {
                        HStack(spacing: DFSpacing.md) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(DFColor.gold)
                            Text("Tiếp tục với Google")
                                .font(DFFont.callout().bold())
                        }
                        .foregroundStyle(DFColor.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DFSpacing.lg)
                        .background(DFColor.bg3)
                        .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: DFRadius.lg)
                                .stroke(DFColor.border, lineWidth: 1)
                        )
                    }
                }
                .padding(DFSpacing.xxl)
            }
            .background(DFColor.bg)
            .navigationTitle(mode == .login ? "Đăng Nhập" : "Đăng Ký")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                        .foregroundStyle(DFColor.textDim)
                }
            }
            .sheet(isPresented: $showGoogleOAuth) {
                GoogleOAuthView(
                    onAuthSuccess: { token, accessToken in
                        Task {
                            do {
                                isSubmitting = true
                                try await state.handleOAuthResult(token: token, accessToken: accessToken)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isSubmitting = false
                        }
                    },
                    onAuthFailure: { errorMsg in
                        errorMessage = errorMsg
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    private var modeTabs: some View {
        HStack(spacing: 0) {
            tabButton("Đăng Nhập", active: mode == .login) { mode = .login; errorMessage = nil }
            tabButton("Đăng Ký", active: mode == .register) { mode = .register; errorMessage = nil }
        }
        .background(DFColor.bg3)
        .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
    }

    private func tabButton(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DFFont.callout())
                .foregroundStyle(active ? DFColor.bg : DFColor.textDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DFSpacing.lg)
                .background(active ? DFColor.gold : .clear)
        }
        .buttonStyle(.plain)
    }

    private func field(_ label: String, text: Binding<String>,
                       hint: String? = nil, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: DFSpacing.xs) {
            TextField(label, text: text)
                .font(DFFont.body())
                .foregroundStyle(DFColor.text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(DFSpacing.lg)
                .background(DFColor.bg3)
                .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
            if let hint {
                Text(hint)
                    .font(DFFont.small())
                    .foregroundStyle(DFColor.textMuted)
            }
        }
    }

    private func secureField(_ label: String, text: Binding<String>, hint: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: DFSpacing.xs) {
            SecureField(label, text: text)
                .font(DFFont.body())
                .foregroundStyle(DFColor.text)
                .padding(DFSpacing.lg)
                .background(DFColor.bg3)
                .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
            if let hint {
                Text(hint)
                    .font(DFFont.small())
                    .foregroundStyle(DFColor.textMuted)
            }
        }
    }

    private var canSubmit: Bool {
        guard username.count >= 3, password.count > 6 else { return false }
        if mode == .register {
            return !email.isEmpty && !phone.isEmpty
        }
        return true
    }

    private func submit() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            if mode == .login {
                try await state.login(username: username, password: password)
            } else {
                try await state.register(username: username, password: password,
                                         email: email, phone: phone)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ChangePasswordSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var current = ""
    @State private var newPassword = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: DFSpacing.xl) {
                Text("Đổi mật khẩu sẽ đăng xuất mọi thiết bị khác.")
                    .font(DFFont.caption())
                    .foregroundStyle(DFColor.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)

                SecureField("Mật khẩu hiện tại", text: $current)
                    .padding(DFSpacing.lg)
                    .background(DFColor.bg3)
                    .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
                    .foregroundStyle(DFColor.text)

                SecureField("Mật khẩu mới", text: $newPassword)
                    .padding(DFSpacing.lg)
                    .background(DFColor.bg3)
                    .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
                    .foregroundStyle(DFColor.text)

                if let errorMessage {
                    Text(errorMessage)
                        .font(DFFont.caption())
                        .foregroundStyle(.red)
                }

                Button { Task { await submit() } } label: {
                    Text("Cập nhật")
                        .font(DFFont.headline())
                        .foregroundStyle(DFColor.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DFSpacing.lg)
                        .background(newPassword.count > 6 ? DFColor.gold : DFColor.goldDim.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: DFRadius.lg))
                }
                .disabled(newPassword.count <= 6 || isSubmitting)

                Spacer()
            }
            .padding(DFSpacing.xxl)
            .background(DFColor.bg)
            .navigationTitle("Đổi mật khẩu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }.foregroundStyle(DFColor.textDim)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func submit() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await state.changePassword(current: current, new: newPassword)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
