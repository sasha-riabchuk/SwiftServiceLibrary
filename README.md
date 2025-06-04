# ServiceLibrary

Swift micro library providing simple HTTP service abstractions. It defines a `ServiceProtocol` describing an endpoint and utilities for building and executing `URLRequest`s. It also includes helpers for multipart uploads and request interception.

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
    var interceptors: InterceptorsStorage? { nil }
}
```

Perform a request using a `URLSession`:

```swift
let session = URLSession.shared
let users: [User] = try await MyService.users.perform(
    authorizationPlugin: nil,
    baseUrl: nil,
    urlSession: session
)
```

## Macro Usage (Swift 5.9+)

You can also declare services using the provided macros. Annotate an enum with `@Service` and cases with HTTP method macros:

```swift
@Service(baseURL: "https://example.com")
enum MacroService {
    @Get(endpoint: "/users")
    case users
}
```

The generated implementation conforms to `ServiceProtocol` so you can call `perform` just like the manual example.

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

## License

MIT
