import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Intercepts a response after a request is sent.
public protocol ResponseInterceptor: Sendable {
    /// Allows custom handling of a request and returns the response.
    /// - Parameters:
    ///   - request: The request to execute.
    ///   - service: The service that generated the request.
    ///   - session: The session performing the request.
    /// - Returns: The data and response produced by the session.
    func intercept(
        _ request: URLRequest,
        service: any ServiceProtocol,
        for session: URLSessionProtocol
    ) async throws
        -> (Data, URLResponse)
}
