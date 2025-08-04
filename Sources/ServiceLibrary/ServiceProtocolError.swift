import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public enum ServiceProtocolError: Error, Sendable {
    case invalidURL(any ServiceProtocol)
    /// ResponseCode
    case responseCode(Int)
    /// Unexpected Response
    case unexpectedResponse(HTTPURLResponse?)
    /// Interceptor Error
    case interceptorError
}
