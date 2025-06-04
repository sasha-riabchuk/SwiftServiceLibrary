import Foundation

public protocol Interceptor {
    func adapt(
        _ urlRequest: URLRequest,
        for session: URLSessionProtocol
    ) async throws -> URLRequest

    func retry(
        _ request: URLRequest,
        for session: URLSessionProtocol
    ) async throws -> (Data, URLResponse)
}
