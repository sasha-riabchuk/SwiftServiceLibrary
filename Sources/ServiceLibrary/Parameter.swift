import Foundation

/// Key-value pair representing a request parameter.
public struct Parameter: @unchecked Sendable {
    /// The parameter key.
    public let key: String
    /// The parameter value.
    public let value: Any

    /// Creates a parameter instance.
    /// - Parameters:
    ///   - key: Parameter key.
    ///   - value: Parameter value.
    public init(key: String, value: Any) {
        self.key = key
        self.value = value
    }
}
