import Foundation

public struct RetryInterceptor: Interceptor {
    /// The maximum number of retry attempts.
    private let retryCount: Int
    /// The HTTP status codes that should trigger a retry.
    private let retryStatusCodes: Set<Int>
    /// The delay between retry attempts
    private let delayBetweenRetries: UInt64

    /// Initializes a new `RetryInterceptor`.
    /// - Parameters:
    ///  - retryStatusCodes: A set of HTTP status codes that should trigger a retry. Defaults to `[429, 500, 502, 503, 504]`.
    ///  - retryCount: The maximum number of retry attempts. Defaults to `2`.
    ///  - delayBetweenRetries: The delay between retry attempts in nanoseconds. Defaults to `1_500_000_000` (1.5 seconds).
    ///  /// - Example:
    ///  ///   ```swift
    ///  ///   let retryInterceptor = RetryInterceptor(
    ///  ///       retryStatusCodes: [429, 500, 502, 503, 504],
    ///  ///       retryCount: 2,
    ///  ///       delayBetweenRetries: 1_500_000_000
    ///  ///   )
    ///  ///   ```
    public init(
        retryStatusCodes: Set<Int> = [429, 500, 502, 503, 504],
        retryCount: Int = 2,
        delayBetweenRetries: UInt64 = 1_500_000_000
    ) {
        self.retryStatusCodes = retryStatusCodes
        self.retryCount = retryCount
        self.delayBetweenRetries = delayBetweenRetries
    }

    public func adapt(
        _ urlRequest: URLRequest,
        for _: URLSessionProtocol
    ) async throws -> URLRequest {
        urlRequest
    }

    /// Intercept the execution of a URL request, with retry logic.
    /// - Parameters:
    ///   - urlRequest: The URL request to be processed.
    ///   - urlSession: The URL session for the request.
    /// - Returns: The data and response of the HTTP request.
    /// - Throws: An error if the request cannot be executed after the maximum number of retry attempts.
    public func retry(
        _ request: URLRequest,
        for session: URLSessionProtocol
    ) async throws -> (Data, URLResponse) {
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
                if case let ServiceProtocolError.responseCode(statusCode) = error,
                   retryStatusCodes.contains(statusCode) {
                    try await Task.sleep(nanoseconds: delayBetweenRetries)
                    continue
                }

                if case let ServiceProtocolError.unexpectedResponse(response) = error,
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
