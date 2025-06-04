import Foundation

public enum ServiceProtocolError: Error {
    case invalidURL
    /// ResponseCode
    case responseCode(Int)
    /// Unexpected Response
    case unexpectedResponse(HTTPURLResponse?)

    case anotherError

    case interceptorError
}
