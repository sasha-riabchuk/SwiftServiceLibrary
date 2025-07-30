import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import ServiceLibrary
import XCTest

enum MockService {
    case getUsers
}

extension MockService: ServiceProtocol, BearerAuthorizable {
    var baseURL: URL? {
        URL(string: "https://mock.com")
    }

    var path: String? {
        switch self {
        case .getUsers:
            return "/users"
        }
    }

    var httpMethod: ServiceLibrary.HTTPMethod {
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

}

final class ServiceLibraryTests: XCTestCase {
    func testGetUrl() async throws {
        let urlRequest: URLRequest = try await MockService.getUsers.urlRequest()
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://mock.com/users")
    }
}

final class URLEncodedFormParameterEncoderTests: XCTestCase {
    func testThatQueryIsBodyEncodedAndProperContentTypeIsSetForGETRequest() async throws {
        let service = MockService.getUsers
        let newRequest = try await service.urlRequest()

        XCTAssertEqual(newRequest.httpMethod, "GET")
        XCTAssertEqual(newRequest.headers["Content-Type"], "application/x-www-form-urlencoded; charset=utf-8")
        XCTAssertNil(newRequest.httpBody)
    }

    func testBearerInterceptorAddsHeader() async throws {
        let service = MockService.getUsers
        let session = MockURLSession()
        session.mockData = "{}".data(using: .utf8)
        session.mockResponse = HTTPURLResponse(url: URL(string: "https://mock.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)

        let bearer = BearerInterceptor(token: "123")
        _ = try await service.perform(
            urlSession: session,
            requestInterceptors: [bearer],
            handleResponse: { data, _ in data }
        ) as Data
        XCTAssertEqual(session.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer 123")
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
