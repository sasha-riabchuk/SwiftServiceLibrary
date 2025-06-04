import XCTest
import ServiceLibrary // Ensure ServiceLibrary is imported to access macros and types
import Foundation    // For URL, URLQueryItem

// Define a sample interceptor for testing
struct TestInterceptor: Interceptor, Sendable {
    let id: UUID = UUID()
    func adapt(_ request: URLRequest, for session: URLSession) async throws -> URLRequest { request }
    func retry(_ request: URLRequest, for session: URLSessionProtocol, dueTo error: Error, previousAttempts: Int) async throws -> (Data, URLResponse) {
        throw error // Simple retry that just rethrows
    }
}
 struct TestInterceptor2: Interceptor, Sendable {
     let id: UUID = UUID()
     func adapt(_ request: URLRequest, for session: URLSession) async throws -> URLRequest { request }
     func retry(_ request: URLRequest, for session: URLSessionProtocol, dueTo error: Error, previousAttempts: Int) async throws -> (Data, URLResponse) {
         throw error
     }
 }

// Define Parameter struct if it's not accessible or for clarity in tests
// Assuming Parameter is defined elsewhere and accessible.
// If not, it would be:
// public struct Parameter: ExpressibleByArrayLiteral, Sendable {
//     public let key: String
//     public let value: Any
//     public init(key: String, value: Any) {
//         self.key = key
//         self.value = value
//     }
//     public init(arrayLiteral elements: Any...) {
//        self.key = elements[0] as! String
//        self.value = elements[1]
//     }
// }


@Service(baseURL: "https://api.example.com")
enum ComprehensiveTestService {
    @Get(endpoint: "/users")
    @Header([.init(key: "X-API-Version", value: "1")])
    @Query([.init(key: "active", value: true)])
    case listUsers

    @Post(endpoint: "/users")
    @Params([.init(key: "name", value: "Jules"), .init(key: "role", value: "Engineer")], encoding: .json)
    @Interceptor([TestInterceptor()])
    case createUser

    @Put(endpoint: "/users/123")
    @Params([.init(key: "status", value: "updated")], encoding: .formUrlEncoded)
    case updateUser

    @Delete(endpoint: "/users/123")
    case deleteUser

    @Patch(endpoint: "/users/123/settings")
    @Params([.init(key: "notifications", value: false)]) // Test default .json encoding
    case updateSettings

    @Get(endpoint: "/files/download")
    @Interceptor([TestInterceptor(), TestInterceptor2()]) // Test multiple interceptors
    case downloadFile

    @Get(endpoint: "/simple")
    case simpleGet // Test minimal setup
}

final class MacroGeneratedServiceTests: XCTestCase {
    func testListUsers() {
        let service = ComprehensiveTestService.listUsers
        XCTAssertEqual(service.baseURL?.absoluteString, "https://api.example.com")
        XCTAssertEqual(service.path, "/users")
        XCTAssertEqual(service.httpMethod, .get)
        XCTAssertEqual(service.headers?["X-API-Version"], "1")
        XCTAssertNotNil(service.queryItems?.first(where: { $0.name == "active" && $0.value == "true" }))
        XCTAssertNil(service.parameters)
        XCTAssertNil(service.parametersEncoding)
        XCTAssertNil(service.interceptors)
    }

    func testCreateUser() {
        let service = ComprehensiveTestService.createUser
        XCTAssertEqual(service.baseURL?.absoluteString, "https://api.example.com")
        XCTAssertEqual(service.path, "/users")
        XCTAssertEqual(service.httpMethod, .post)
        XCTAssertEqual(service.parameters?["name"] as? String, "Jules")
        XCTAssertEqual(service.parameters?["role"] as? String, "Engineer")
        XCTAssertEqual(service.parametersEncoding, .json)
        XCTAssertNotNil(service.interceptors)
        XCTAssertEqual(service.interceptors?.interceptorsCount(), 1) // Helper needed in InterceptorsStorage
    }

    func testUpdateUser() {
        let service = ComprehensiveTestService.updateUser
        XCTAssertEqual(service.path, "/users/123")
        XCTAssertEqual(service.httpMethod, .put)
        XCTAssertEqual(service.parameters?["status"] as? String, "updated")
        XCTAssertEqual(service.parametersEncoding, .formUrlEncoded)
    }

    func testDeleteUser() {
        let service = ComprehensiveTestService.deleteUser
        XCTAssertEqual(service.path, "/users/123")
        XCTAssertEqual(service.httpMethod, .delete)
        XCTAssertNil(service.parameters)
        XCTAssertNil(service.parametersEncoding)
    }

    func testUpdateSettings() {
        let service = ComprehensiveTestService.updateSettings
        XCTAssertEqual(service.path, "/users/123/settings")
        XCTAssertEqual(service.httpMethod, .patch)
        XCTAssertEqual(service.parameters?["notifications"] as? Bool, false)
        XCTAssertEqual(service.parametersEncoding, .json) // Default for @Params
    }

    func testDownloadFile() {
        let service = ComprehensiveTestService.downloadFile
        XCTAssertEqual(service.path, "/files/download")
        XCTAssertEqual(service.httpMethod, .get)
        XCTAssertNotNil(service.interceptors)
        XCTAssertEqual(service.interceptors?.interceptorsCount(), 2) // Helper needed
    }

    func testSimpleGet() {
        let service = ComprehensiveTestService.simpleGet
        XCTAssertEqual(service.baseURL?.absoluteString, "https://api.example.com")
        XCTAssertEqual(service.path, "/simple")
        XCTAssertEqual(service.httpMethod, .get)
        XCTAssertNil(service.headers)
        XCTAssertNil(service.queryItems)
        XCTAssertNil(service.parameters)
        XCTAssertNil(service.parametersEncoding)
        XCTAssertNil(service.interceptors)
    }
}
