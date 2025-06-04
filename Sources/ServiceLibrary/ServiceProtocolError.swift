import Foundation

public enum ServiceProtocolError: Error {
    case invalidURL(any ServiceProtocol)
    /// ResponseCode
    case responseCode(Int)
    /// Unexpected Response
    case unexpectedResponse(HTTPURLResponse?)
    
    case anotherError
    
    case interceptorError
}
