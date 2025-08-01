import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// HTTP method definitions.
/// See https://tools.ietf.org/html/rfc7231#section-4.3
public enum HTTPMethod: String, Sendable {
    case options = "OPTIONS"
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case trace = "TRACE"
    case connect = "CONNECT"
}
