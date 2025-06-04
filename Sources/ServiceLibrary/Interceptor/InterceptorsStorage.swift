import Foundation

public struct InterceptorsStorage: Sendable {
    private var interceptors: [Interceptor]

    public init(interceptors: [Interceptor]) {
        self.interceptors = interceptors
    }

    public func interceptorsCount() -> Int { interceptors.count }

    func performRequestInterception(_ request: URLRequest) async throws -> URLRequest {
        var modifiedRequest = request
        for interceptor in interceptors {
            let result = try await interceptor.adapt(modifiedRequest, for: URLSession.shared)
            modifiedRequest = result
        }
        return modifiedRequest
    }

    func performResponseInterception(
        _ urlRequest: URLRequest,
        urlSession: URLSessionProtocol
    ) async throws -> (Data, URLResponse) {
        var data: Data?
        var response: URLResponse?

        for interceptor in interceptors {
            let result = try await interceptor.retry(urlRequest, for: urlSession)
            (data, response) = (result.0, result.1)
        }

        guard let unwrappedData = data, let unwrappedResponse = response else {
            throw ServiceProtocolError.interceptorError
        }

        return (unwrappedData, unwrappedResponse)
    }
}
