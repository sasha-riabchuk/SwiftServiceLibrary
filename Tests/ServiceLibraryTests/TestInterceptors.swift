import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif
@testable import ServiceLibrary

protocol BearerAuthorizable {}

@propertyWrapper
struct TokenStorage {
    var wrappedValue: String
}

actor BearerInterceptor: RequestInterceptor {
    @TokenStorage var token: String
    init(token: String) {
        _token = TokenStorage(wrappedValue: token)
    }

    func adapt(_ request: URLRequest, service: any ServiceProtocol, for _: URLSessionProtocol) async throws -> URLRequest {
        guard service is BearerAuthorizable else { return request }
        var r = request
        r.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return r
    }
}

struct RetryInterceptor: ResponseInterceptor {
    let retryCount: Int
    func intercept(
        _ request: URLRequest,
        service _: any ServiceProtocol,
        for session: URLSessionProtocol
    ) async throws -> (Data, URLResponse) {
        for attempt in 0 ... retryCount {
            do {
                return try await session.data(for: request)
            } catch {
                if attempt == retryCount { throw error }
            }
        }
        throw ServiceProtocolError.interceptorError
    }
}

class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var dataTaskCallCount = 0
    var lastRequest: URLRequest?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        dataTaskCallCount += 1
        lastRequest = request
        if let mockError {
            throw mockError
        }
        guard let mockData, let mockResponse else {
            throw NSError(domain: "MockURLSessionError", code: 1, userInfo: nil)
        }
        return (mockData, mockResponse)
    }

    func upload(for request: URLRequest, from _: Data) async throws -> (Data, URLResponse) {
        lastRequest = request
        return try await data(for: request)
    }
}
