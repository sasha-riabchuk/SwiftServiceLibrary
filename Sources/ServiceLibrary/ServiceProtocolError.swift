import Foundation

public enum ServiceProtocolError: Error, Sendable {
    case invalidURL
    /// ResponseCode
    case responseCode(Int)
    /// Unexpected Response
    case unexpectedResponse(HTTPURLResponse?)

    case anotherError

    case interceptorError
}
