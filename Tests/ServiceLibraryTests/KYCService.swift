import Foundation
import ServiceLibrary

@Service(baseURL: "https://www.mock.com")
enum KYCService {
    @Get(endpoint: "/users")
    case status
}
