import Combine
import Foundation
@testable import ServiceLibrary
import XCTest

import XCTest

struct EmptyModel: Codable {}

class RetryInterceptorTests: XCTestCase {
    var sut: ServiceProtocol! // System Under Test
    var urlSession: URLSessionProtocol!

    override func setUp() {
        super.setUp()
        sut = KYCService.status
        urlSession = MockURLSession()
    }

    func testPerformRetriesOnRetryableStatusCode() async {
        let retryableStatusCode = 429 // This is a retryable status code
        (urlSession as! MockURLSession).mockResponse = HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: retryableStatusCode, httpVersion: nil, headerFields: nil)
        (urlSession as! MockURLSession).mockData = Data()

        do {
            let _: EmptyModel = try await sut.perform(
                authorizationPlugin: nil,
                baseUrl: nil,
                urlSession: urlSession)
            XCTFail("Perform should throw an error")
        } catch {
        }

        XCTAssertEqual((urlSession as! MockURLSession).dataTaskCallCount, 5)
    }
}

// Mock URLSession
class MockURLSession: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var dataTaskCallCount = 0

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let mockError = mockError {
            throw mockError
        }

        guard let mockData, let mockResponse else {
            throw NSError(domain: "MockURLSessionError", code: 1, userInfo: nil)
        }

        if dataTaskCallCount == 5 {
            let successResponse = HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
            return (mockData, successResponse!)
        } else {
            dataTaskCallCount += 1
            return (mockData, mockResponse)
        }
    }
}
