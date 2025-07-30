import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import ServiceLibrary
import XCTest

struct EmptyModel: Codable {}

class RetryInterceptorTests: XCTestCase {
    var sut: ServiceProtocol!
    var urlSession: MockURLSession!

    override func setUp() {
        super.setUp()
        sut = MockService.getUsers
        urlSession = MockURLSession()
    }

    func testPerformRetriesOnRetryableStatusCode() async {
        let retryableStatusCode = 429
        urlSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: retryableStatusCode,
            httpVersion: nil,
            headerFields: [:]
        )!
        urlSession.mockError = URLError(.badServerResponse)
        urlSession.mockData = Data()

        do {
            let _: EmptyModel = try await sut.perform(
                urlSession: urlSession,
                responseInterceptors: [RetryInterceptor(retryCount: 4)])
            XCTFail("Perform should throw an error")
        } catch {
        }

        XCTAssertEqual(urlSession.dataTaskCallCount, 5)
    }
}

