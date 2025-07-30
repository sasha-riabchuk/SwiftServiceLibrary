import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Intercepts requests before being sent.
public protocol RequestInterceptor: Sendable {
    /// Allows modification of a URLRequest before it is sent.
    /// - Parameters:
    ///   - request: The original request.
    ///   - service: The `ServiceProtocol` that generated the request.
    ///   - session: The session performing the request.
    /// - Returns: The adapted request.
    func adapt(_ request: URLRequest, service: any ServiceProtocol, for session: URLSessionProtocol) async throws -> URLRequest
}

/// Intercepts a response after a request is sent.
public protocol ResponseInterceptor: Sendable {
    /// Allows custom handling of a request and returns the response.
    /// - Parameters:
    ///   - request: The request to execute.
    ///   - service: The service that generated the request.
    ///   - session: The session performing the request.
    /// - Returns: The data and response produced by the session.
    func intercept(_ request: URLRequest, service: any ServiceProtocol, for session: URLSessionProtocol) async throws -> (Data, URLResponse)
}
