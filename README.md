# EdiNetworkKit

EdiNetworkKit is a lightweight Swift networking layer that focuses on defining HTTP endpoints in a concise way. It ships with helpers for building and executing `URLRequest`s, handling multipart uploads and composing request/response interceptors. The codebase is built with Swift's strict concurrency checking enabled so types are safe to use from concurrent contexts.

## Installation

Add the package to your `Package.swift` dependencies:

```swift
.package(url: "https://github.com/yourOrg/EdiNetworkKit.git", from: "1.0.0")
```

Then add `EdiNetworkKit` as a dependency for your target.

## Basic Usage

Create an enum describing your API and conform it to `Endpoint`:

```swift
enum MyService {
    case users
}

extension MyService: Endpoint {
    var baseURL: URL? { URL(string: "https://example.com") }
    var path: String? {
        switch self { case .users: return "/users" }
    }
    var httpMethod: HTTPMethod { .get }
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

`EdiNetworkKit` does not ship with concrete interceptors but provides the `RequestInterceptor` and `ResponseInterceptor` protocols so you can implement your own middleware. Interceptors can adapt requests (for example to inject authentication headers) or inspect responses before they are returned.

```swift
actor BearerInterceptor: RequestInterceptor {
    private let token: String
    init(token: String) { self.token = token }

    func adapt(_ request: URLRequest, service: any Endpoint, for _: URLSessionProtocol) async throws -> URLRequest {
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

The accompanying unit tests demonstrate how a retry interceptor can be composed for testing purposes. You can use those as inspiration to build logging, retry or metrics interceptors.

## License

MIT
