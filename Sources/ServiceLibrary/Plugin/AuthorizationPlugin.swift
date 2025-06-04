import Foundation

public protocol AuthorizationPlugin {
    func prepare(_ request: URLRequest, service: any ServiceProtocol) -> URLRequest
}
