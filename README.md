# ServiceLibrary

Swift micro library providing simple HTTP service abstractions. It defines a `ServiceProtocol` describing an endpoint and utilities for building and executing `URLRequest`s. It also includes helpers for multipart uploads and request interception.

The library is thread safe and built with Swift's strict concurrency checking enabled. All public types conform to `Sendable` where possible.

## Installation

Add the package to your `Package.swift` dependencies:

```swift
.package(url: "https://github.com/yourOrg/ServiceLibrary.git", from: "1.0.0")
```

Then add `ServiceLibrary` as a dependency for your target.

## Basic Usage

Create an enum describing your API and conform it to `ServiceProtocol`:

```swift
enum MyService {
    case users
}

extension MyService: ServiceProtocol {
    var baseURL: URL? { URL(string: "https://example.com") }
    var path: String? {
        switch self { case .users: return "/users" }
    }
    var httpMethod: HttpMethod { .get }
    var headers: [String: String]? { defaultHeaders().dictionary }
    var queryItems: [URLQueryItem]? { nil }
    var parameters: [String: Any]? { nil }
    var parametersEncoding: BodyParameterEncoding? { .json }
}
```

Perform a request using a `URLSession`:

```swift
let session = URLSession.shared
let users: [User] = try await MyService.users.perform(
    urlSession: session
)
```

For multipart uploads you can use `MultipartFormData`:

```swift
let data = Data() // your file data
var form = MultipartFormData()
form.append(data, withName: "file", fileName: "file.dat", mimeType: "application/octet-stream")
  let response: String = try await MyService.users.performUpload(
      multipartFormData: form,
      urlSession: session
  )
```

## Interceptors

`ServiceLibrary` does not ship with concrete interceptors but provides the `RequestInterceptor` and
`ResponseInterceptor` protocols so you can implement your own middleware.

```swift
actor BearerInterceptor: RequestInterceptor {
    private let token: String
    init(token: String) { self.token = token }

    func adapt(_ request: URLRequest, service: any ServiceProtocol, for _: URLSessionProtocol) async throws -> URLRequest {
        var r = request
        r.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return r
    }
}

let bearer = BearerInterceptor(token: "secret")
let data: Data = try await MyService.users.perform(
    urlSession: session,
    requestInterceptors: [bearer],
    handleResponse: { $0 }
)
```

The accompanying unit tests demonstrate how a retry interceptor can be composed for testing purposes.

## License

MIT
