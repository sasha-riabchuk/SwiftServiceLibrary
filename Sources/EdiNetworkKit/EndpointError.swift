import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public enum EndpointError: Error, Sendable {
    case invalidURL(any Endpoint)
    /// ResponseCode
    case responseCode(Int)
    /// Unexpected Response
    case unexpectedResponse(HTTPURLResponse?)
    /// Interceptor Error
    case interceptorError
}
