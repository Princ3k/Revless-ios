// NetworkManager.swift
// Revless
//
// Async/await networking layer. All API calls go through this singleton.
//
// Design decisions:
//   • JSONDecoder uses .convertFromSnakeCase so backend snake_case maps to
//     Swift camelCase automatically — no manual CodingKeys needed in models.
//   • Bearer token is injected automatically from Keychain on every request.
//   • The login endpoint uses application/x-www-form-urlencoded (OAuth2 spec),
//     while all other endpoints use application/json.

import Foundation

// MARK: - Error types

enum NetworkError: LocalizedError {
    case badURL
    case unauthorized
    case paymentRequired   // 402 — out of search credits
    case notFound
    case conflict
    case serverError(Int, String?)
    case decodingError(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Invalid request URL."
        case .unauthorized:
            return "Incorrect email or password."
        case .paymentRequired:
            return "Insufficient search credits. Verify a route to earn more."
        case .notFound:
            return "The requested resource was not found."
        case .conflict:
            return "An account with this email already exists."
        case .serverError(let code, let detail):
            return detail ?? "Server error (\(code)). Please try again."
        case .decodingError:
            return "Unexpected response from server."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - NetworkManager

final class NetworkManager {

    static let shared = NetworkManager()
    private init() {}

    private let baseURL = URL(string: "https://revless-api.onrender.com/api/v1")!

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    // MARK: - Auth (OAuth2 Password Flow)

    /// POST /auth/login/access-token
    /// Uses application/x-www-form-urlencoded as required by the OAuth2 spec.
    func login(email: String, password: String) async throws -> LoginResponse {
        let url = baseURL.appendingPathComponent("auth/login/access-token")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        // OAuth2 form fields use "username" even though we pass an email
        let body = "username=\(email.formEncoded)&password=\(password.formEncoded)"
        request.httpBody = body.data(using: .utf8)
        return try await perform(request)
    }

    /// POST /auth/register
    func register(email: String, password: String) async throws -> User {
        try await post("auth/register", body: RegisterRequest(email: email, password: password))
    }

    /// GET /auth/me — returns the authenticated user's profile (email, credits, tenant).
    func getMe() async throws -> User {
        try await get("auth/me")
    }

    /// GET /tenant-requests/me — latest request for this user, or `nil` if none.
    func getMyTenantRequest() async throws -> TenantRequestRead? {
        let url = baseURL.appendingPathComponent("tenant-requests").appendingPathComponent("me")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        attachBearerToken(to: &request)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw NetworkError.unknown(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.unknown(URLError(.badServerResponse))
        }
        switch http.statusCode {
        case 200...299:
            if let s = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines), s == "null" {
                return nil
            }
            do {
                return try decoder.decode(TenantRequestRead.self, from: data)
            } catch {
                throw NetworkError.decodingError(error)
            }
        case 401:
            throw NetworkError.unauthorized
        default:
            let detail = (try? decoder.decode(APIErrorDetail.self, from: data))?.detail
            throw NetworkError.serverError(http.statusCode, detail)
        }
    }

    /// POST /tenant-requests — ask to add your airline workspace (users without a tenant).
    func createTenantRequest(airlineName: String, airlineCode: String, message: String?) async throws -> TenantRequestRead {
        struct Body: Codable {
            let airlineName: String
            let airlineCode: String
            let message: String?
        }
        return try await post(
            "tenant-requests",
            body: Body(airlineName: airlineName, airlineCode: airlineCode, message: message)
        )
    }

    /// GET /search/history — server-side recent searches for Home.
    func getSearchHistory(limit: Int = 20) async throws -> [SearchHistoryItem] {
        try await get(
            "search/history",
            queryItems: [URLQueryItem(name: "limit", value: "\(limit)")]
        )
    }

    /// GET /auth/me/verifications — crowd verifications the user submitted.
    func getMyVerifications(limit: Int = 30) async throws -> [VerificationHistoryItem] {
        try await get(
            "auth/me/verifications",
            queryItems: [URLQueryItem(name: "limit", value: "\(limit)")]
        )
    }

    /// GET /agreements/matrix — rules for tenant + pending peer-review uploads.
    func getAgreementMatrix() async throws -> AgreementMatrixResponse {
        try await get("agreements/matrix")
    }

    /// POST /agreements/documents — multipart upload (PDF / image).
    func uploadAgreementDocument(
        carrierIata: String,
        fileData: Data,
        fileName: String,
        mimeType: String
    ) async throws -> AgreementDocumentUploadResponse {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        func append(_ string: String) {
            body.append(Data(string.utf8))
        }

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"carrier_iata\"\r\n\r\n")
        append(carrierIata.uppercased().trimmingCharacters(in: .whitespaces))
        append("\r\n")

        let safeName = fileName.replacingOccurrences(of: "\"", with: "_")
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"\(safeName)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        append("\r\n--\(boundary)--\r\n")

        let url = baseURL.appendingPathComponent("agreements/documents")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        attachBearerToken(to: &request)
        request.httpBody = body
        return try await perform(request)
    }

    /// POST /agreements/documents/{id}/approve — peer approval vote.
    func approveAgreementDocument(documentId: UUID) async throws -> DocumentApproveResponse {
        let path = "agreements/documents/\(documentId.uuidString)/approve"
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        attachBearerToken(to: &request)
        return try await perform(request)
    }

    /// GET /agreements/documents/{id}/file — raw bytes for preview.
    func downloadAgreementDocumentFile(documentId: UUID) async throws -> Data {
        let path = "agreements/documents/\(documentId.uuidString)/file"
        guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL else { throw NetworkError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        attachBearerToken(to: &request)
        return try await performData(request)
    }

    // MARK: - Generic authenticated requests

    /// GET request. Automatically attaches the stored Bearer token.
    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false
        ) else { throw NetworkError.badURL }
        if !queryItems.isEmpty { components.queryItems = queryItems }
        guard let url = components.url else { throw NetworkError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        attachBearerToken(to: &request)
        return try await perform(request)
    }

    /// POST request with a JSON body. Automatically attaches the stored Bearer token.
    func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        attachBearerToken(to: &request)
        request.httpBody = try encoder.encode(body)
        return try await perform(request)
    }

    // MARK: - Private helpers

    private func attachBearerToken(to request: inout URLRequest) {
        if let token = KeychainHelper.get(KeychainHelper.jwtTokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func performData(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw NetworkError.unknown(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.unknown(URLError(.badServerResponse))
        }

        switch http.statusCode {
        case 200...299:
            return data
        case 401:
            throw NetworkError.unauthorized
        case 404:
            throw NetworkError.notFound
        default:
            let detail = (try? decoder.decode(APIErrorDetail.self, from: data))?.detail
            throw NetworkError.serverError(http.statusCode, detail)
        }
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw NetworkError.unknown(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.unknown(URLError(.badServerResponse))
        }

        switch http.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingError(error)
            }
        case 401:
            throw NetworkError.unauthorized
        case 402:
            throw NetworkError.paymentRequired
        case 404:
            throw NetworkError.notFound
        case 409:
            throw NetworkError.conflict
        default:
            // Try to surface the FastAPI detail message if present
            let detail = (try? decoder.decode(APIErrorDetail.self, from: data))?.detail
            throw NetworkError.serverError(http.statusCode, detail)
        }
    }
}

// MARK: - Internal helpers

/// Matches FastAPI's standard error envelope: {"detail": "..."}
private struct APIErrorDetail: Decodable {
    let detail: String
}

private extension String {
    /// Percent-encodes a string for use as a URL form value (RFC 3986 unreserved chars only).
    var formEncoded: String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}
