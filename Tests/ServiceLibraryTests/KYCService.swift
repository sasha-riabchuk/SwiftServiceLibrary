import Foundation
import ServiceLibrary

@Service(baseURL: "https://www.mock.com")
enum KYCService: Sendable {
    @Get(endpoint: "/users")
    case status
}
