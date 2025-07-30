import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol ServiceProtocol {
    /// The target's base `URL`.
    var baseURL: URL? { get }

    /// The path to be appended to `baseURL` to form the full `URL`.
    var path: String? { get }

    /// The HTTP method used in the request.
    var httpMethod: HTTPMethod { get }

    /// The headers to be used in the request.
    var headers: [String: String]? { get }

    /// The query items to be appended to the URL.
    var queryItems: [URLQueryItem]? { get }

    /// Request Parameters
    var parameters: [String: Any]? { get }

    /// A type used to define how a set of parameters are applied to a `URLRequest`.
    var parametersEncoding: BodyParameterEncoding? { get }

}
