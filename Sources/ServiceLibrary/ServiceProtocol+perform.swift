//
//  ServiceProtocol+perform.swift
//
//
//  Created by Ondřej Veselý on 01.12.2022.
//

import Combine
import Foundation

public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {} // Conform URLSession to the protocol

public extension ServiceProtocol {
    /// Designated request-making method.
    /// - Parameters:
    ///   - interceptor: An optional `Interceptor` that can intercept the request before it is sent.
    ///   - authorizationPlugin: A Plugin receives callbacks to perform side effects wherever a request is sent.
    ///   - baseUrl: The service's base `URL`. If provided,  it will be used in preference to `ServiceProtocol.baseURL`
    ///   - urlSession: URL Sessions for a request.
    ///   - logger: Logger to log message of requests made.
    ///   - decoder: An object that decodes instances of a data type from JSON objects.
    ///   - handleResponse: Response handler that handles custom object decoding
    /// - Returns: Decoded object
    func perform<D: Decodable>(authorizationPlugin: AuthorizationPlugin?,
                               baseUrl: URL?,
                               urlSession: URLSessionProtocol,
                               decoder: JSONDecoder = .init(),
                               handleResponse: ((Data, URLResponse) throws -> D)? = nil) async throws -> D {
        var urlRequest = try urlRequest(authorizationPlugin: authorizationPlugin, baseUrl: baseUrl)

        guard let interceptors else {
            let (data, urlResponse) = try await urlSession.data(for: urlRequest)
            guard let handleResponse else {
                return try Self.handleResponse(data: data, urlResponse: urlResponse, decoder: decoder)
            }
            return try handleResponse(data, urlResponse)
        }

        // set cookies
        urlRequest.addCookies()

        print(">>> \(urlRequest.cURL(pretty: false))")

        let request = try await interceptors.performRequestInterception(urlRequest)
        let (modifiedData, modifiedUrlResponse) = try await interceptors.performResponseInterception(request, urlSession: urlSession)

        guard let handleResponse else {
            return try Self.handleResponse(data: modifiedData, urlResponse: modifiedUrlResponse, decoder: decoder)
        }

        return try handleResponse(modifiedData, modifiedUrlResponse)
    }

    /// Designated request-making method.
    ///
    /// Uploads data to a URL based on the specified URL request.
    /// - Parameters:
    ///   - authorizationPlugin: A Plugin receives callbacks to perform side effects wherever a request is sent.
    ///   - baseUrl: The service's base `URL`. If provided,  it will be used in preference to `ServiceProtocol.baseURL`
    ///   - urlSession: URL Sessions for a request.
    ///   - logger: Logger to log message of requests made.
    ///   - decoder: An object that decodes instances of a data type from JSON objects.
    ///   - handleResponse: Response handler that handles custom object decoding
    /// - Returns:Decoded object
    func performUpload<D: Decodable>(authorizationPlugin: AuthorizationPlugin? = nil,
                                     baseUrl: URL? = nil,
                                     multipartFormData: MultipartFormData,
                                     urlSession: URLSession = URLSession.shared,
                                     decoder: JSONDecoder = JSONDecoder(),
                                     handleResponse: ((Data, URLResponse) throws -> D)? = nil) async throws -> D {
        var urlRequest = try urlRequest(authorizationPlugin: authorizationPlugin, baseUrl: baseUrl)

        // Here's where we add interceptors if they exist
        if let interceptors = interceptors {
            urlRequest = try await interceptors.performRequestInterception(urlRequest)
        }

        // set cookies
        urlRequest.addCookies()

        let requestData = try multipartFormData.encode()

        urlRequest.headers.add(
            .init(name: "Content-Type", value: "multipart/form-data; boundary=\(multipartFormData.boundary)")
        )
//        urlRequest.headers.add(
//            .init(name: "Content-Length", value: "\(requestData.count)")
//        )

        print(">>> \(urlRequest.cURL(pretty: false))")

        let (data, urlResponse) = try await urlSession.upload(for: urlRequest, from: requestData)

        // Also adding interceptors for response here
        let (modifiedData, modifiedUrlResponse) = try await interceptors?.performResponseInterception(urlRequest, urlSession: urlSession) ?? (data, urlResponse)

        // Now, if the handleResponse exists, use it, else go to the default
        guard let handleResponse = handleResponse else {
            return try Self.handleResponse(data: modifiedData, urlResponse: modifiedUrlResponse, decoder: decoder)
        }
        return try handleResponse(modifiedData, modifiedUrlResponse)
    }

    /// Response handler that handles custom object decoding.
    ///
    /// - Parameters:
    ///   - data: Received data from the URL request.
    ///   - urlResponse: The metadata associated with the response to a URL load request,
    ///     independent of protocol and URL scheme.
    ///   - logger: Optional logger to log requests made.
    ///   - decoder: An object that decodes instances of a data type from JSON objects.
    ///   - successCodes: Set of HTTP status codes to consider as successful responses.
    ///                   Defaults to the range 200...299.
    /// - Returns: The custom decoded object.
    /// - Throws: `ServiceProtocolError.unexpectedResponse` if the URL response is not an HTTPURLResponse,
    ///           or `ServiceProtocolError.responseCode` if the response status code is not within the successCodes.
    ///
    /// - Example:
    ///   ```
    ///   let successCodes: Set<Int> = Set(200...299).union([400])
    ///   do {
    ///       let responseObject: MyResponseObject = try handleResponse(data: responseData,
    ///                                                                 urlResponse: urlResponse,
    ///                                                                 decoder: jsonDecoder,
    ///                                                                 successCodes: successCodes)
    ///       // Handle the response object
    ///       // ...
    ///   } catch {
    ///       // Handle the error
    ///       // ...
    ///   }
    ///   ```
    static func handleResponse<D: Decodable>(data: Data,
                                             urlResponse: URLResponse,
                                             decoder: JSONDecoder,
                                             successCodes: Set<Int> = Set(200 ... 299)) throws -> D {
        guard let response = urlResponse as? HTTPURLResponse else {
            throw ServiceProtocolError.unexpectedResponse(urlResponse as? HTTPURLResponse)
        }

        guard successCodes.contains(response.statusCode) else {
            print("<<< \(urlResponse)")
            throw ServiceProtocolError.responseCode(response.statusCode)
        }
        do {
            let string = String(data: data, encoding: .utf8)
            print("<<< \(response) data: \(string ?? "nil")")
            return try decoder.decode(D.self, from: data)
        } catch {
            print(String(data: data, encoding: .utf8))
            throw error
        }
    }
}

extension URLRequest {
    /// Adds a saved cookie to http headers
    mutating func addCookies(cookieStorage: HTTPCookieStorage = HTTPCookieStorage.shared) {
        guard let url = url, let cookies = cookieStorage.cookies(for: url) else {
            return
        }
        let headers = HTTPCookie.requestHeaderFields(with: cookies)
        headers.forEach { key, value in
            self.headers.add(name: key, value: value)
        }
    }
}
