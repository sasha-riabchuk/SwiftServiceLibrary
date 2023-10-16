//
//  RetryInterceptor.swift
//
//
//  Created by Oleksandr Riabchuk on 24.07.2023.
//

import Foundation

/// `RetryInterceptor` is an implementation of `Interceptor` that adds retry logic to HTTP requests.
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

                debugPrint("{OR} retry count is \(i)")
                guard let httpResponse = urlResponse as? HTTPURLResponse else {
                    debugPrint("{OR} urlResponse is nil")
                    throw ServiceProtocolError.unexpectedResponse(urlResponse as? HTTPURLResponse)
                }

                if retryStatusCodes.contains(httpResponse.statusCode) {
                    if i == retryCount {
                        debugPrint("{OR} statuc code is invalid and must return \(httpResponse.statusCode)")
                        return (data, urlResponse)
                    }
                    debugPrint("{OR} status code does contain retry status code \(httpResponse.statusCode)")
                    throw ServiceProtocolError.responseCode(httpResponse.statusCode)
                }

                debugPrint("{OR} request is done \(httpResponse.statusCode)")
                return (data, urlResponse)
            } catch {
                if case ServiceProtocolError.responseCode(let statusCode) = error,
                   retryStatusCodes.contains(statusCode) {
                    try await Task.sleep(nanoseconds: delayBetweenRetries)
                    debugPrint("{OR} wait and contain \(statusCode) in loop \(i)")
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

        debugPrint("Throw error outside")
        throw ServiceProtocolError.interceptorError
    }
}
