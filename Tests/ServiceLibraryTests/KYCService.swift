import Foundation
import ServiceLibrary

@Service(baseURL: "https://www.mock.com")
enum MockService: Sendable {
    @Get(endpoint: "/users")
    case status
}
