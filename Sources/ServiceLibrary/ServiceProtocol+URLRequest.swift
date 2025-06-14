import Foundation

extension ServiceProtocol {
    /// A value that identifies the location of a resource for this service.
    public func url(baseUrl: URL? = nil) -> URL? {
        guard let url = URL(service: self, baseUrl: baseUrl) else { return nil }
        guard let queryItems else {
            return url
        }
        return url.appendingLegacy(queryItems: queryItems)
    }

    /// A URL request for this service
    public func urlRequest(authorizationPlugin: AuthorizationPlugin? = nil, baseUrl: URL? = nil) throws -> URLRequest {
        guard let url = url(baseUrl: baseUrl) else {
            throw ServiceProtocolError.invalidURL(self)
        }

        var request = URLRequest(url: url)

        if parameters != nil, let parametersEncoding {
            switch parametersEncoding {
            case .json:
                request.httpBody = try jsonEncodedParameters()
            case .formUrlEncoded:
                // x-www-form-urlencoded
                request.setValue(parametersEncoding.rawValue, forHTTPHeaderField: "Content-Type")
                request.httpBody = try formUrlEncodedParameters()
            case .multipartFormData:
                // multipart/form-data
                request.setValue(parametersEncoding.rawValue, forHTTPHeaderField: "Content-Type")
            }
        }

        // HTTP method
        request.httpMethod = httpMethod.rawValue

        request.timeoutInterval = 180.0

        // Headers
        request.allHTTPHeaderFields = headers

        guard let authorizationPlugin else {
            return request
        }
        return authorizationPlugin.prepare(request, service: self)
    }
}

extension ServiceProtocol {
    func jsonEncodedParameters() throws -> Data {
        try JSONSerialization.data(withJSONObject: parameters ?? [:], options: [])
    }

    func formUrlEncodedParameters(using encoding: String.Encoding = .utf8) throws -> Data {
        guard let parameters else { return Data() }
        var components = URLComponents()
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        return components.percentEncodedQuery?.data(using: encoding) ?? .init()
    }
}
