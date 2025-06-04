import Foundation

public struct RetryInterceptor: RequestInterceptor {
    /// The maximum number of retry attempts.
    private let retryCount: Int
    /// The HTTP status codes that should trigger a retry.
    private let retryStatusCodes: Set<Int> = [429, 500, 502, 503, 504]
    /// The delay between retry attempts
    private let delayBetweenRetries: UInt64 = 1_500_000_000

    public init(retryCount: Int = 2) {
        self.retryCount = retryCount
    }

    public func adapt(_ urlRequest: URLRequest,
                      for session: URLSessionProtocol) async throws -> URLRequest {
        urlRequest
    }

    /// Intercept the execution of a URL request, with retry logic.
    /// - Parameters:
    ///   - urlRequest: The URL request to be processed.
    ///   - urlSession: The URL session for the request.
    /// - Returns: The data and response of the HTTP request.
    /// - Throws: An error if the request cannot be executed after the maximum number of retry attempts.
    public func retry(_ request: URLRequest,
                      for session: URLSessionProtocol) async throws -> (Data, URLResponse) {
        for i in 0 ... retryCount {
            do {
                let (data, urlResponse) = try await session.data(for: request)

                guard let httpResponse = urlResponse as? HTTPURLResponse else {
                    throw ServiceProtocolError.unexpectedResponse(urlResponse as? HTTPURLResponse)
                }

                if retryStatusCodes.contains(httpResponse.statusCode) {
                    if i == retryCount {
                        return (data, urlResponse)
                    }
                    throw ServiceProtocolError.responseCode(httpResponse.statusCode)
                }

                return (data, urlResponse)
            } catch {
                if case ServiceProtocolError.responseCode(let statusCode) = error,
                   retryStatusCodes.contains(statusCode) {
                    try await Task.sleep(nanoseconds: delayBetweenRetries)
                    continue
                }

                if case ServiceProtocolError.unexpectedResponse(let response) = error,
                   let response,
                   retryStatusCodes.contains(response.statusCode) {
                    try await Task.sleep(nanoseconds: delayBetweenRetries)
                    continue
                }
                throw error
            }
        }

        throw ServiceProtocolError.interceptorError
    }
}
