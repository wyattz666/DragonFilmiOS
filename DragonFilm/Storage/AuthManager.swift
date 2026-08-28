import Foundation
import Security

/// Stores the JWT in the Keychain so it survives app reinstalls as long as the
/// user doesn't explicitly revoke it (only a password change bumps `token_version`
/// server-side, which makes the token invalid anyway).
final class AuthManager {
    private let keychainService = "com.dragonfilm.ios.auth"
    private let tokenKey = "jwt"

    var token: String? {
        get { read() }
        set {
            if let newValue { write(newValue) }
            else { delete() }
        }
    }

    var isLoggedIn: Bool { token != nil }

    func logout() {
        token = nil
    }

    func parseUser(from payload: String) -> User? {
        let parts = payload.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        guard let data = Data(base64urlEncoded: String(parts[1])) else { return nil }
        return try? JSONDecoder().decode(UserPayload.self, from: data).asUser
    }

    // MARK: - Keychain

    private func write(_ value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    private func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenKey
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Payload helpers

    private struct UserPayload: Decodable {
        let sub: String?
        let username: String?
        let exp: Int?
        var asUser: User {
            User(id: sub ?? "", username: username ?? "", email: "", phone: "",
                 avatarURL: "", role: "user", isAdmin: false, createdAt: "")
        }
    }
}

extension Data {
    init?(base64urlEncoded string: String) {
        var s = string.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while s.count % 4 != 0 { s.append("=") }
        self.init(base64Encoded: s)
    }
}
