import Foundation
import OSLog

/// The one network seam. `URLSession` is wrapped rather than used directly so
/// tests can replay canned responses without touching the network.
protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

struct URLSessionTransport: HTTPTransport {
    let session: URLSession

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Thin JSON-over-HTTP client: builds URLs, decodes bodies and maps every
/// failure mode to an `AppFailure`.
struct APIClient: Sendable {
    static let defaultTimeout: TimeInterval = 15

    private static let logger = Logger(subsystem: "com.lugonja.savora", category: "APIClient")

    private let transport: any HTTPTransport
    private let baseURL: URL
    private let timeout: TimeInterval

    init(transport: any HTTPTransport, baseURL: URL, timeout: TimeInterval = APIClient.defaultTimeout) {
        self.transport = transport
        self.baseURL = baseURL
        self.timeout = timeout
    }

    func get<Response: Decodable>(_ path: String, query: [String: String] = [:], as type: Response.Type = Response.self) async throws(AppFailure) -> Response {
        let url = makeURL(path: path, query: query)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.data(for: URLRequest(url: url, timeoutInterval: timeout))
        } catch is URLError {
            throw .network
        } catch {
            Self.logger.error("Request to \(url) failed: \(error)")
            throw .unknown
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw .unknown
        }
        if httpResponse.statusCode == 404 {
            throw .notFound
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw .server(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            Self.logger.error("Unexpected payload shape for \(url): \(error)")
            throw .parsing
        }
    }

    private func makeURL(path: String, query: [String: String]) -> URL {
        let url = baseURL.appending(path: path)
        guard !query.isEmpty else {
            return url
        }
        return url.appending(queryItems: query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) })
    }
}
