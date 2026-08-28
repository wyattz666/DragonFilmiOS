import SwiftUI
import AuthenticationServices

@Observable
final class AppState {
    var selectedTab: AppTab = .home
    var currentUser: User?

    let auth = AuthManager()
    let localStore = LocalStore()
    private(set) var cloudSync: CloudSync

    var isLoggedIn: Bool { auth.token != nil }

    init() {
        cloudSync = CloudSync(store: localStore, auth: auth)
        if auth.token != nil {
            Task { await loadProfile() }
        }
    }

    // MARK: - Auth

    func login(username: String, password: String) async throws {
        let body: [String: Any] = ["username": username, "password": password]
        let response: APIResponseEnvelope = try await APIClient.shared.post("/api/auth/login", body: body)
        auth.token = response.token
        currentUser = response.user
        await cloudSync.sync()
    }

    func register(username: String, password: String, email: String, phone: String) async throws {
        let body: [String: Any] = [
            "username": username, "password": password,
            "email": email, "phone": phone
        ]
        let response: APIResponseEnvelope = try await APIClient.shared.post("/api/auth/register", body: body)
        auth.token = response.token
        currentUser = response.user
        await cloudSync.sync()
    }

    func changePassword(current: String, new: String) async throws {
        guard let token = auth.token else { throw APIError.http(status: 401, message: "Chưa đăng nhập.", code: nil) }
        let body: [String: Any] = ["currentPassword": current, "newPassword": new]
        let _: APIResponseEnvelope = try await APIClient.shared.post("/api/user/password", body: body, token: token)
        // Server bumps token_version which invalidates the old token.
        // The response carries a new one.
    }

    func logout() {
        auth.token = nil
        currentUser = nil
    }

    // MARK: - Profile

    func loadProfile() async {
        guard let token = auth.token else { return }
        do {
            let user: APIUserEnvelope = try await APIClient.shared.get("/api/user/profile", token: token)
            currentUser = user.user
        } catch {}
        await cloudSync.sync()
    }

    func uploadAvatar(imageData: Data) async throws {
        guard let token = auth.token else { throw APIError.http(status: 401, message: "Chưa đăng nhập.", code: nil) }
        let b64 = "data:image/jpeg;base64," + imageData.base64EncodedString()
        let body: [String: Any] = ["avatar": b64]
        let resp: APIUserEnvelope = try await APIClient.shared.post("/api/user/avatar", body: body, token: token)
        currentUser = resp.user
    }

    func handleOAuthResult(token: String?, accessToken: String?) async throws {
        if let accessToken = accessToken, !accessToken.isEmpty {
            let body: [String: Any] = ["accessToken": accessToken]
            let resp: APIResponseEnvelope = try await APIClient.shared.post("/api/auth/oauth/google/callback", body: body)
            if let t = resp.token {
                auth.token = t
            }
            if let u = resp.user {
                currentUser = u
            } else if let t = auth.token {
                let userResp: APIUserEnvelope = try await APIClient.shared.get("/api/user/profile", token: t)
                currentUser = userResp.user
            }
        } else if let token = token, !token.isEmpty {
            auth.token = token
            let userResp: APIUserEnvelope = try await APIClient.shared.get("/api/user/profile", token: token)
            currentUser = userResp.user
        } else {
            throw APIError.decoding("Không nhận được token đăng nhập từ Google.")
        }
        await cloudSync.sync()
    }

    func googleOAuth(token oauthToken: String) async throws {
        try await handleOAuthResult(token: oauthToken, accessToken: nil)
    }
}

// MARK: - Local envelopes matching the Worker's `{ok, user, token}` shapes

private struct APIResponseEnvelope: Codable {
    let ok: Bool
    let token: String?
    let user: User?
}

private struct APIUserEnvelope: Codable {
    let ok: Bool
    let user: User
}

