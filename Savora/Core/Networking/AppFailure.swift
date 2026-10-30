import Foundation

/// Every way a request can fail, as a closed set. Repositories throw it with
/// typed `throws(AppFailure)`, so callers handle failures exhaustively and the
/// UI maps them to localized copy instead of raw error messages.
enum AppFailure: Error, Equatable, Sendable {
    case network
    case server(statusCode: Int)
    case notFound
    case parsing
    case unknown
}
