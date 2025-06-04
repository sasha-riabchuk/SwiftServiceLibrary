import Combine
import Foundation
@testable import ServiceLibrary
import XCTest

enum MockService {
    case getUsers
}

extension MockService: ServiceProtocol {
    var baseURL: URL? {
        URL(string: "https://mock.com")
    }

    var path: String? {
        switch self {
        case .getUsers:
            return "/users"
        }
    }

    var httpMethod: ServiceLibrary.HttpMethod {
        switch self {
        case .getUsers:
            return .get
        }
    }

    var headers: [String: String]? {
        defaultHeaders().dictionary
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getUsers:
            return nil
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .getUsers:
            return nil
        }
    }

    var parametersEncoding: ServiceLibrary.BodyParameterEncoding? {
        switch self {
        case .getUsers:
            return .formUrlEncoded
        }
    }

    var interceptors: ServiceLibrary.InterceptorsStorage? {
        InterceptorsStorage(interceptors: [
            RetryInterceptor(retryCount: 3)
        ])
    }
}

final class ServiceLibraryTests: XCTestCase {
    func testGetUrl() throws {
        let urlRequest: URLRequest = try KYCService.status.urlRequest()
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://www.mock.com/users")
    }

    func testMacroGeneratedMembers() throws {
        let service = KYCService.status
        XCTAssertEqual(service.baseURL, URL(string: "https://www.mock.com"))
        XCTAssertEqual(service.httpMethod, .get)
        XCTAssertEqual(service.path, "/users")
    }
}

final class URLEncodedFormParameterEncoderTests: XCTestCase {
    func testThatQueryIsBodyEncodedAndProperContentTypeIsSetForGETRequest() throws {
        let service = MockService.getUsers
        let newRequest = try service.urlRequest()

        XCTAssertEqual(newRequest.httpMethod, "GET")
        XCTAssertEqual(newRequest.headers["Content-Type"], "application/json; charset=utf-8")
        XCTAssertNil(newRequest.httpBody)
    }
}

extension Data {
    var asString: String {
        String(decoding: self, as: UTF8.self)
    }

    func asJSONObject() throws -> Any {
        try JSONSerialization.jsonObject(with: self, options: .allowFragments)
    }
}
