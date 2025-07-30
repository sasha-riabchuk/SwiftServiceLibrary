import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol RequestInterceptor {
    func adapt(_ request: URLRequest, service: any ServiceProtocol, for session: URLSessionProtocol) async throws -> URLRequest
}

public protocol ResponseInterceptor {
    func intercept(_ request: URLRequest, service: any ServiceProtocol, for session: URLSessionProtocol) async throws -> (Data, URLResponse)
}
