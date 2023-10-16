//
//  ServiceProtocol.swift
//
//
//  Created by Ondřej Veselý on 01.12.2022.
//

import Foundation

/// The protocol used to define the specifications necessary for a `Service`.
public protocol ServiceProtocol {
    /// The target's base `URL`.
    var baseURL: URL? { get }

    /// The path to be appended to `baseURL` to form the full `URL`.
    var path: String? { get }

    /// The HTTP method used in the request.
    var httpMethod: HttpMethod { get }

    /// The headers to be used in the request.
    var headers: [String: String]? { get }

    /** URL Parameters to be appended to URL

     URL parameters (known also as “query strings”
     or “URL query parameters”)
     are elements inserted in your URLs

     To identify a URL parameter, refer to the portion of the URL
     that comes after a question mark (?).
     URL parameters are made of a key and a value,
     separated by an equal sign (=).
     Multiple parameters are each then separated by an ampersand (&).
     */
    var queryItems: [URLQueryItem]? { get }

    /// Request Parameters
    var parameters: [String: Any]? { get }

    /// A type used to define how a set of parameters are applied to a `URLRequest`.
    var parametersEncoding: BodyParameterEncoding? { get }
    
    var interceptors: InterceptorsStorage? { get }
}
