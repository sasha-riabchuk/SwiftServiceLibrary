/// Defines the authorization requirements for a service.
public enum AuthorizableType: Equatable, Sendable {
    /// No authorization required.
    case none
    /// Uses a token without a specific resource.
    case token
    /// Uses a api key for authorization.
    case apiKey
}
