import Combine
import Foundation
@testable import ServiceLibrary
import XCTest

enum KYCService {
    case status
    case questionnaire
}

extension KYCService: ServiceProtocol {
    var baseURL: URL? {
        URL(string: "https://www.csast.csas.cz")
    }

    var path: String? {
        switch self {
        case .status:
            return "/webapi/api/v1/kyck/info"
        case .questionnaire:
            return "/webapi/api/v1/kyck/questionnaire"
        }
    }

    var httpMethod: ServiceLibrary.HttpMethod {
        switch self {
        case .status:
            return .get
        case .questionnaire:
            return .post
        }
    }

    var headers: [String: String]? {
        defaultHeaders().dictionary
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .status, .questionnaire:
            return nil
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .questionnaire:
            return ["property": "property"]
        case .status:
            return nil
        }
    }

    var parametersEncoding: ServiceLibrary.BodyParameterEncoding? {
        switch self {
        case .questionnaire:
            return .formUrlEncoded
        case .status:
            return .json
        }
    }

    var interceptors: ServiceLibrary.InterceptorsStorage? {
        InterceptorsStorage(interceptors: [RetryInterceptor(retryCount: 3)])
    }
}

final class ServiceLibraryTests: XCTestCase {
    func testGetUrl() throws {
        let urlRequest: URLRequest = try KYCService.status.urlRequest()
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://www.csast.csas.cz/webapi/api/v1/kyck/info")
    }

    func testGetUrlWithBaseUrl() throws {
        let urlRequest = try KYCService.status.urlRequest(baseUrl: URL(string: "https://www.csas.cz"))
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://www.csas.cz/webapi/api/v1/kyck/info")
    }

    func testianaName() throws {
        let utf8 = String.Encoding.utf8
        XCTAssertEqual(utf8.ianaName, "utf-8")
    }
}

final class URLEncodedFormParameterEncoderTests: XCTestCase {
    func testThatQueryIsBodyEncodedAndProperContentTypeIsSetForPOSTRequest() throws {
        // Given
        let service = KYCService.questionnaire

        // When
        let newRequest = try service.urlRequest()

        // Then
        XCTAssertEqual(newRequest.headers["Content-Type"], "application/x-www-form-urlencoded; charset=utf-8")
        XCTAssertEqual(newRequest.httpBody?.asString, "property=property")
        XCTAssertEqual(newRequest.httpMethod, "POST")
    }

    func testThatQueryIsBodyEncodedAndProperContentTypeIsSetForGETRequest() throws {
        // Given
        let service = KYCService.status

        // When
        let newRequest = try service.urlRequest()

        // Then
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
