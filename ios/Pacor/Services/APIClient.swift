import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case server(status: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Bir hata oluştu"
        case .unauthorized:
            return "Oturum süresi doldu"
        case .server(_, let message):
            return message
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var authToken: String?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
        encoder = JSONEncoder()
    }

    func restoreSession() {
        authToken = KeychainService.token
    }

    func setSession(_ response: AuthResponse) {
        authToken = response.token
        KeychainService.saveSession(response)
    }

    func clearSession() {
        authToken = nil
        KeychainService.clearSession()
    }

    func hasSession() -> Bool {
        guard let authToken, !authToken.isEmpty else {
            return KeychainService.isAuthenticated
        }
        return true
    }

    func register(username: String, pin: String) async throws -> AuthResponse {
        try await request(
            path: "/api/auth/register",
            method: "POST",
            body: ["username": username, "pin": pin],
            authenticated: false
        )
    }

    func login(username: String, pin: String) async throws -> AuthResponse {
        try await request(
            path: "/api/auth/login",
            method: "POST",
            body: ["username": username, "pin": pin],
            authenticated: false
        )
    }

    func getCurrentState() async throws -> CurrentState {
        try await request(path: "/api/state", method: "GET")
    }

    func logMeal() async throws -> MealLog {
        try await request(path: "/api/meals/", method: "POST", body: EmptyBody())
    }

    func getMeals(from: String? = nil, to: String? = nil) async throws -> [MealLog] {
        var queryItems: [URLQueryItem] = []
        if let from { queryItems.append(URLQueryItem(name: "from", value: from)) }
        if let to { queryItems.append(URLQueryItem(name: "to", value: to)) }
        var query = ""
        if !queryItems.isEmpty {
            var components = URLComponents()
            components.queryItems = queryItems
            query = components.percentEncodedQuery.map { "?\($0)" } ?? ""
        }
        return try await request(path: "/api/meals\(query)", method: "GET")
    }

    func getPlan() async throws -> PlanSettings {
        try await request(path: "/api/settings/plan", method: "GET")
    }

    func updatePlan(_ plan: PlanSettings) async throws -> PlanSettings {
        try await request(path: "/api/settings/plan", method: "PUT", body: plan)
    }

    func changePinVoid(currentPin: String, newPin: String) async throws {
        try await requestVoid(
            path: "/api/settings/pin",
            method: "PUT",
            body: ["current_pin": currentPin, "new_pin": newPin]
        )
    }

    private struct EmptyBody: Encodable {}

    private func currentToken() -> String? {
        if let authToken, !authToken.isEmpty {
            return authToken
        }
        if let keychainToken = KeychainService.token, !keychainToken.isEmpty {
            authToken = keychainToken
            return keychainToken
        }
        return nil
    }

    private func url(for path: String) -> URL {
        var base = AppConfig.baseURL.absoluteString
        if base.hasSuffix("/") { base.removeLast() }
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        return URL(string: base + normalizedPath)!
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        body: (any Encodable)? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        var urlRequest = URLRequest(url: url(for: path))
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let sentToken: String?
        if authenticated {
            guard let token = currentToken() else {
                throw APIError.unauthorized
            }
            sentToken = token
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            sentToken = nil
        }

        if let body {
            urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            if sentToken != nil {
                await clearSession()
            }
            throw APIError.unauthorized
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let apiError = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.server(
                status: httpResponse.statusCode,
                message: apiError?.error ?? "Bir hata oluştu"
            )
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func requestVoid(
        path: String,
        method: String,
        body: (any Encodable)? = nil,
        authenticated: Bool = true
    ) async throws {
        var urlRequest = URLRequest(url: url(for: path))
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let sentToken: String?
        if authenticated {
            guard let token = currentToken() else {
                throw APIError.unauthorized
            }
            sentToken = token
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            sentToken = nil
        }

        if let body {
            urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            if sentToken != nil {
                await clearSession()
            }
            throw APIError.unauthorized
        }

        if httpResponse.statusCode == 204 {
            return
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let apiError = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.server(
                status: httpResponse.statusCode,
                message: apiError?.error ?? "Bir hata oluştu"
            )
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
