import Foundation

public protocol RequestInterceptor {
    func adapt(_ urlRequest: URLRequest,
               for session: URLSessionProtocol) async throws -> URLRequest

    func retry(_ request: URLRequest,
               for session: URLSessionProtocol) async throws -> (Data, URLResponse)
}

public enum RetryResult {
    case success(Data, URLResponse)
    case failure
}

// MARK: Interceptors Storage

public struct InterceptorsStorage {
    private var interceptors: [RequestInterceptor]

    public init(interceptors: [RequestInterceptor]) {
        self.interceptors = interceptors
    }

    func performRequestInterception(_ request: URLRequest) async throws -> URLRequest {
        var modifiedRequest = request
        for interceptor in interceptors {
            let result = try await interceptor.adapt(modifiedRequest, for: URLSession.shared)
            modifiedRequest = result
        }
        return modifiedRequest
    }

    func performResponseInterception(_ urlRequest: URLRequest, urlSession: URLSessionProtocol) async throws -> (Data, URLResponse) {
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
