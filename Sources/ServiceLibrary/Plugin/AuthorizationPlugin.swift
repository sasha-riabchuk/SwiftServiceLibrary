import Foundation

public protocol AuthorizationPlugin: Sendable {
    func prepare(_ request: URLRequest, service: any ServiceProtocol) -> URLRequest
}
