import Foundation

struct TokenDTO: Decodable {
    let access_token: String
    let token_type: String
}

struct UserOutDTO: Decodable {
    let id: Int
    let email: String
    let phone: String?
    let is_active: Bool
    let is_verified: Bool
    let created_at: String
}

final class AuthService {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = AppConfig.baseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func register(email: String, password: String, phone: String?) async throws -> UserOutDTO {
        let payload: [String: Any] = [
            "email": email,
            "password": password,
            "phone": phone as Any
        ]
        let data = try JSONSerialization.data(withJSONObject: payload, options: [])
        return try await request("auth/register", method: .post, body: data)
    }

    func login(email: String, password: String) async throws -> TokenDTO {
        let form = "username=\(urlEncode(email))&password=\(urlEncode(password))"
        let data = form.data(using: .utf8) ?? Data()
        var request = URLRequest(url: baseURL.appendingPathComponent("auth/login"))
        request.httpMethod = HTTPMethod.post.rawValue
        request.httpBody = data
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await send(request)
    }

    private func request<T: Decodable>(_ path: String, method: HTTPMethod, body: Data?) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await send(request)
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError(message: parseErrorMessage(from: data) ?? "Ошибка сервера (\(http.statusCode))")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func urlEncode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
    }

    private func parseErrorMessage(from data: Data) -> String? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let detail = json["detail"]
        else { return nil }

        if let message = detail as? String {
            return message
        }
        if let list = detail as? [[String: Any]] {
            let messages = list.compactMap { $0["msg"] as? String }
            return messages.joined(separator: "\n")
        }
        return nil
    }
}
