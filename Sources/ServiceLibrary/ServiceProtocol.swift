import Foundation

public protocol ServiceProtocol: Sendable {
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

    /// A storage for interceptors that can modify requests and responses.
    var interceptors: InterceptorsStorage? { get }
}
