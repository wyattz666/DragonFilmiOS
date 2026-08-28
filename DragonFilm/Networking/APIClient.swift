import Foundation

/// Thin wrapper over URLSession. The backend uses a different envelope per
/// endpoint (`{ok, user}`, `{ok, rows}`, and netflix-top10 has no `ok` at all),
/// so callers decode their own envelope type rather than sharing a generic one.
final class APIClient {
    static let shared = APIClient()
    private init() {}

    let baseURL = "https://dragonfilm.pages.dev"

    private let decoder = JSONDecoder()

    /// A stalled QUIC handshake does not trip `timeoutIntervalForRequest` (that
    /// only measures gaps between packets), so a hard resource deadline is set to
    /// make a hung connection fail fast instead of hanging for ~180s.
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    func get<T: Decodable>(_ path: String, query: [String: String] = [:], token: String? = nil) async throws -> T {
        try await send(path, method: "GET", query: query, body: nil, token: token)
    }

    func post<T: Decodable>(_ path: String, body: [String: Any], token: String? = nil) async throws -> T {
        try await send(path, method: "POST", body: body, token: token)
    }

    func patch<T: Decodable>(_ path: String, body: [String: Any], token: String? = nil) async throws -> T {
        try await send(path, method: "PATCH", body: body, token: token)
    }

    func delete<T: Decodable>(_ path: String, body: [String: Any], token: String? = nil) async throws -> T {
        try await send(path, method: "DELETE", body: body, token: token)
    }

    /// Returns the raw upstream body. Used by `/api/source`, whose response is
    /// verbatim KKPhim/OPhim/NguonC/VSMOV JSON with no shared shape.
    func rawData(_ path: String, query: [String: String] = [:]) async throws -> Data {
        let (data, http) = try await perform(path, method: "GET", query: query, body: nil, token: nil)
        try check(http, data)
        return data
    }

    private func send<T: Decodable>(
        _ path: String,
        method: String,
        query: [String: String] = [:],
        body: [String: Any]?,
        token: String?
    ) async throws -> T {
        let (data, http) = try await perform(path, method: method, query: query, body: body, token: token)
        try check(http, data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }

    private func perform(
        _ path: String,
        method: String,
        query: [String: String],
        body: [String: Any]?,
        token: String?
    ) async throws -> (Data, HTTPURLResponse) {
        guard var comps = URLComponents(string: baseURL + path) else { throw APIError.badURL(path) }
        if !query.isEmpty {
            comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = comps.url else { throw APIError.badURL(path) }

        var req = URLRequest(url: url, timeoutInterval: 20)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError.invalidResponse }
        return (data, http)
    }

    /// Surfaces the Vietnamese `error` string the Worker returns so the UI can
    /// show the server's own wording instead of a generic message.
    private func check(_ http: HTTPURLResponse, _ data: Data) throws {
        guard !(200...299).contains(http.statusCode) else { return }
        let envelope = try? decoder.decode(ErrorEnvelope.self, from: data)
        throw APIError.http(status: http.statusCode,
                            message: envelope?.error,
                            code: envelope?.code)
    }

    private struct ErrorEnvelope: Decodable {
        let error: String?
        let code: String?
    }
}

enum APIError: LocalizedError {
    case badURL(String)
    case invalidResponse
    case http(status: Int, message: String?, code: String?)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .badURL(let path):
            return "Đường dẫn không hợp lệ: \(path)"
        case .invalidResponse:
            return "Phản hồi không hợp lệ từ máy chủ."
        case .http(let status, let message, _):
            return message ?? "Máy chủ trả về lỗi \(status)."
        case .decoding:
            return "Không đọc được dữ liệu từ máy chủ."
        }
    }

    /// Server-supplied machine code, e.g. `USERNAME_EXISTS`, `INVALID_LOGIN`.
    var serverCode: String? {
        if case .http(_, _, let code) = self { return code }
        return nil
    }
}
