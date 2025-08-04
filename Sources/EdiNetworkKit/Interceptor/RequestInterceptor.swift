import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Intercepts requests before being sent.
public protocol RequestInterceptor: Sendable {
    /// Allows modification of a URLRequest before it is sent.
    /// - Parameters:
    ///   - request: The original request.
    ///   - service: The `Endpoint` that generated the request.
    ///   - session: The session performing the request.
    /// - Returns: The adapted request.
    func adapt(
        _ request: URLRequest,
        service: any Endpoint,
        for session: URLSessionProtocol
    ) async throws -> URLRequest
}
