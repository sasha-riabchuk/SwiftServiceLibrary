import Foundation

/// A representation of a single HTTP header's name / value pair.
public struct HTTPHeader: Hashable {
    /// Name of the header.
    public let name: String

    /// Value of the header.
    public let value: String

    /// Creates an instance from the given `name` and `value`.
    ///
    /// - Parameters:
    ///   - name:  The name of the header.
    ///   - value: The value of the header.
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

extension HTTPHeader: CustomStringConvertible {
    public var description: String {
        "\(name): \(value)"
    }
}

extension HTTPHeader {
    /// Returns an `Accept` header.
    ///
    /// - Parameter value: The `Accept` value.
    /// - Returns:         The header.
    public static func accept(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Accept", value: value)
    }

    /// Returns an `Accept-Charset` header.
    ///
    /// - Parameter value: The `Accept-Charset` value.
    /// - Returns:         The header.
    public static func acceptCharset(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Accept-Charset", value: value)
    }

    /// Returns an `Accept-Language` header.
    ///
    /// Alamofire offers a default Accept-Language header that accumulates and encodes the system's preferred languages.
    /// Use `HTTPHeader.defaultAcceptLanguage`.
    ///
    /// - Parameter value: The `Accept-Language` value.
    ///
    /// - Returns:         The header.
    public static func acceptLanguage(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Accept-Language", value: value)
    }

    /// Returns an `Accept-Encoding` header.
    ///
    /// Alamofire offers a default accept encoding value that provides the most common values. Use
    /// `HTTPHeader.defaultAcceptEncoding`.
    ///
    /// - Parameter value: The `Accept-Encoding` value.
    ///
    /// - Returns:         The header
    public static func acceptEncoding(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Accept-Encoding", value: value)
    }

    /// Returns a `Basic` `Authorization` header using the `username` and `password` provided.
    ///
    /// - Parameters:
    ///   - username: The username of the header.
    ///   - password: The password of the header.
    ///
    /// - Returns:    The header.
    public static func authorization(username: String, password: String) -> HTTPHeader {
        let credential = Data("\(username):\(password)".utf8).base64EncodedString()

        return authorization("Basic \(credential)")
    }

    /// Returns a `Bearer` `Authorization` header using the `bearerToken` provided
    ///
    /// - Parameter bearerToken: The bearer token.
    ///
    /// - Returns:               The header.
    public static func authorization(bearerToken: String) -> HTTPHeader {
        authorization("Bearer \(bearerToken)")
    }

    /// Returns an `Authorization` header.
    ///
    /// Alamofire provides built-in methods to produce `Authorization` headers. For a Basic `Authorization` header use
    /// `HTTPHeader.authorization(username:password:)`. For a Bearer `Authorization` header, use
    /// `HTTPHeader.authorization(bearerToken:)`.
    ///
    /// - Parameter value: The `Authorization` value.
    ///
    /// - Returns:         The header.
    public static func authorization(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Authorization", value: value)
    }

    /// Returns a `Content-Disposition` header.
    ///
    /// - Parameter value: The `Content-Disposition` value.
    ///
    /// - Returns:         The header.
    public static func contentDisposition(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Content-Disposition", value: value)
    }

    /// Returns a `Content-Type` header.
    ///
    /// All Alamofire `ParameterEncoding`s and `ParameterEncoder`s
    /// set the `Content-Type` of the request, so it may not be necessary to manually
    /// set this value.
    ///
    /// - Parameter value: The `Content-Type` value.
    ///
    /// - Returns:         The header.
    public static func contentType(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Content-Type", value: value)
    }

    /// Returns a `User-Agent` header.
    ///
    /// - Parameter value: The `User-Agent` value.
    ///
    /// - Returns:         The header.
    public static func userAgent(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "User-Agent", value: value)
    }
}

extension Array where Element == HTTPHeader {
    /// Case-insensitively finds the index of an `HTTPHeader` with the provided name, if it exists.
    func index(of name: String) -> Int? {
        let lowercasedName = name.lowercased()
        return firstIndex { $0.name.lowercased() == lowercasedName }
    }
}

// MARK: - Defaults

extension HTTPHeaders {
    /// The default set of `HTTPHeaders` used by Alamofire. Includes `Accept-Encoding`, `Accept-Language`, and
    /// `User-Agent`.
    public static let `default`: HTTPHeaders = [
        .defaultAcceptEncoding,
        .defaultAcceptLanguage,
        .defaultUserAgent
    ]

    public static let defaultAcceptJson: HTTPHeaders = [
        .defaultAcceptEncoding,
        .defaultAcceptLanguage,
        .defaultUserAgent,
        HTTPHeader(name: "Content-Type", value: "application/json; charset=utf8")
    ]
}

extension HTTPHeader {
    /// Returns Alamofire's default `Accept-Encoding` header, appropriate for the encodings supported by particular OS
    /// versions.
    ///
    /// See the [Accept-Encoding HTTP header documentation](https://tools.ietf.org/html/rfc7230#section-4.2.3) .
    public static let defaultAcceptEncoding: HTTPHeader = {
        let encodings: [String]
        if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) {
            encodings = ["br", "gzip", "deflate"]
        } else {
            encodings = ["gzip", "deflate"]
        }

        return .acceptEncoding(encodings.qualityEncoded())
    }()

    /// Returns Alamofire's default `Accept-Language` header, generated by querying `Locale` for the user's
    /// `preferredLanguages`.
    ///
    /// See the [Accept-Language HTTP header documentation](https://tools.ietf.org/html/rfc7231#section-5.3.5).
    public static let defaultAcceptLanguage: HTTPHeader = .acceptLanguage(Locale.preferredLanguages.prefix(6).qualityEncoded())

    /// Returns Alamofire's default `User-Agent` header.
    ///
    /// See the [User-Agent header documentation](https://tools.ietf.org/html/rfc7231#section-5.5.3).
    ///
    /// Example: `iOS Example/1.0 (org.alamofire.iOS-Example; build:1; iOS 13.0.0) Alamofire/5.0.0`
    public static let defaultUserAgent: HTTPHeader = {
        let info = Bundle.main.infoDictionary
        let executable = (info?["CFBundleExecutable"] as? String) ??
            (ProcessInfo.processInfo.arguments.first?.split(separator: "/").last.map(String.init)) ??
            "Unknown"
        let bundle = info?["CFBundleIdentifier"] as? String ?? "Unknown"
        let appVersion = info?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let appBuild = info?["CFBundleVersion"] as? String ?? "Unknown"

        let osNameVersion: String = {
            let version = ProcessInfo.processInfo.operatingSystemVersion
            let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
            let osName: String = {
                #if os(iOS)
                    #if targetEnvironment(macCatalyst)
                        return "macOS(Catalyst)"
                    #else
                        return "iOS"
                    #endif
                #elseif os(watchOS)
                    return "watchOS"
                #elseif os(tvOS)
                    return "tvOS"
                #elseif os(macOS)
                    return "macOS"
                #elseif os(Linux)
                    return "Linux"
                #elseif os(Windows)
                    return "Windows"
                #else
                    return "Unknown"
                #endif
            }()

            return "\(osName) \(versionString)"
        }()

        let userAgent = "\(executable)/\(appVersion) (\(bundle); build:\(appBuild); \(osNameVersion))"

        return .userAgent(userAgent)
    }()
}

extension Collection where Element == String {
    func qualityEncoded() -> String {
        enumerated().map { index, encoding in
            let quality = 1.0 - (Double(index) * 0.1)
            return "\(encoding);q=\(quality)"
        }.joined(separator: ", ")
    }
}

// MARK: - System Type Extensions

extension URLRequest {
    /// Returns `allHTTPHeaderFields` as `HTTPHeaders`.
    public var headers: HTTPHeaders {
        get { allHTTPHeaderFields.map(HTTPHeaders.init) ?? HTTPHeaders() }
        set { allHTTPHeaderFields = newValue.dictionary }
    }
}

extension HTTPURLResponse {
    /// Returns `allHeaderFields` as `HTTPHeaders`.
    public var headers: HTTPHeaders {
        (allHeaderFields as? [String: String]).map(HTTPHeaders.init) ?? HTTPHeaders()
    }
}

extension URLSessionConfiguration {
    /// Returns `httpAdditionalHeaders` as `HTTPHeaders`.
    public var headers: HTTPHeaders {
        get { (httpAdditionalHeaders as? [String: String]).map(HTTPHeaders.init) ?? HTTPHeaders() }
        set { httpAdditionalHeaders = newValue.dictionary }
    }
}
