import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Abstraction of ``URLSession`` used for testing and injection.
public protocol URLSessionProtocol: Sendable {
    /// Performs a data request.
    func data(for request: URLRequest) async throws -> (Data, URLResponse)

    /// Performs a data upload request.
    func upload(for request: URLRequest, from bodyData: Data) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol, @unchecked Sendable {
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: nil)
    }

    public func upload(for request: URLRequest, from bodyData: Data) async throws -> (Data, URLResponse) {
        try await upload(for: request, from: bodyData, delegate: nil)
    }
}

extension ServiceProtocol {
    /// Designated request-making method.
    /// - Parameters:
    ///   - baseUrl: Optional service base URL overriding `ServiceProtocol.baseURL`.
    ///   - urlSession: The URL session used to perform requests.
    ///   - requestInterceptors: Interceptors executed before the request is sent.
    ///   - responseInterceptors: Interceptors executed after the request is sent.
    ///   - decoder: A `JSONDecoder` used to decode the response.
    ///   - handleResponse: Custom response handler.
    /// - Returns: Decoded object
    public func perform<D: Decodable>(
        baseUrl: URL? = nil,
        urlSession: URLSessionProtocol,
        requestInterceptors: [RequestInterceptor] = [],
        responseInterceptors: [ResponseInterceptor] = [],
        decoder: JSONDecoder = .init(),
        handleResponse: ((Data, URLResponse) throws -> D)? = nil
    ) async throws -> D {
        var urlRequest = try await urlRequest(baseUrl: baseUrl)

        urlRequest.addCookies()

        for interceptor in requestInterceptors {
            urlRequest = try await interceptor.adapt(urlRequest, service: self, for: urlSession)
        }

        let (data, urlResponse): (Data, URLResponse)
        if responseInterceptors.isEmpty {
            (data, urlResponse) = try await urlSession.data(for: urlRequest)
        } else {
            var tmpData: Data?
            var tmpResponse: URLResponse?
            for interceptor in responseInterceptors {
                let result = try await interceptor.intercept(urlRequest, service: self, for: urlSession)
                tmpData = result.0
                tmpResponse = result.1
            }
            guard let unwrappedData = tmpData, let unwrappedResponse = tmpResponse else {
                throw ServiceProtocolError.interceptorError
            }
            (data, urlResponse) = (unwrappedData, unwrappedResponse)
        }

        guard let handleResponse else {
            return try Self.handleResponse(data: data, urlResponse: urlResponse, decoder: decoder)
        }

        return try handleResponse(data, urlResponse)
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
    public func performUpload<D: Decodable>(
        baseUrl: URL? = nil,
        multipartFormData: MultipartFormData,
        urlSession: URLSessionProtocol = URLSession.shared,
        requestInterceptors: [RequestInterceptor] = [],
        responseInterceptors: [ResponseInterceptor] = [],
        decoder: JSONDecoder = JSONDecoder(),
        handleResponse: ((Data, URLResponse) throws -> D)? = nil
    ) async throws -> D {
        var urlRequest = try await urlRequest(baseUrl: baseUrl)

        // set cookies
        urlRequest.addCookies()

        let requestData = try multipartFormData.encode()

        urlRequest.headers.add(
            .init(
                name: "Content-Type",
                value: "\(BodyParameterEncoding.multipartFormData); boundary=\(multipartFormData.boundary)"
            )
        )

        urlRequest.headers.add(
            .init(
                name: "Content-Length", value: "\(requestData.count)"
            )
        )

        for interceptor in requestInterceptors {
            urlRequest = try await interceptor.adapt(urlRequest, service: self, for: urlSession)
        }

        let performUpload: () async throws -> (Data, URLResponse) = {
            try await urlSession.upload(for: urlRequest, from: requestData)
        }

        let (data, urlResponse): (Data, URLResponse)

        if responseInterceptors.isEmpty {
            (data, urlResponse) = try await performUpload()
        } else {
            var tmpData: Data?
            var tmpResponse: URLResponse?
            for interceptor in responseInterceptors {
                let result = try await interceptor.intercept(urlRequest, service: self, for: urlSession)
                tmpData = result.0
                tmpResponse = result.1
            }
            guard let unwrappedData = tmpData, let unwrappedResponse = tmpResponse else {
                throw ServiceProtocolError.interceptorError
            }
            (data, urlResponse) = (unwrappedData, unwrappedResponse)
        }

        guard let handleResponse else {
            return try Self.handleResponse(data: data, urlResponse: urlResponse, decoder: decoder)
        }
        return try handleResponse(data, urlResponse)
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
    public static func handleResponse<D: Decodable>(
        data: Data,
        urlResponse: URLResponse,
        decoder: JSONDecoder,
        successCodes: Set<Int> = Set(200 ... 299)
    ) throws -> D {
        guard let response = urlResponse as? HTTPURLResponse else {
            throw ServiceProtocolError.unexpectedResponse(urlResponse as? HTTPURLResponse)
        }

        guard successCodes.contains(response.statusCode) else {
            throw ServiceProtocolError.responseCode(response.statusCode)
        }
        do {
            let string = String(data: data, encoding: .utf8)
            return try decoder.decode(D.self, from: data)
        } catch {
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
        for (key, value) in headers {
            self.headers.add(name: key, value: value)
        }
    }
}
