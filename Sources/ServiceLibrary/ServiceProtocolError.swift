//
//  ServiceProtocolError.swift
//
//
//  Created by Ondřej Veselý on 01.12.2022.
//

import Foundation

public enum ServiceProtocolError: Error {
    /// unable to create URL
    case invalidURL(any ServiceProtocol)
    /// ResponseCode
    case responseCode(Int)
    /// Unexpected Response
    case unexpectedResponse(HTTPURLResponse?)
    
    case anotherError
    
    case interceptorError
}
