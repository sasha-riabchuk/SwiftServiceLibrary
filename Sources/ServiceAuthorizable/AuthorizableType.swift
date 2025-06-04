/// Defines the authorization requirements for a service.
public enum AuthorizableType: Equatable {
    /// No authorization required.
    case none
    /// Uses a token without a specific resource.
    case token0
    /// Uses a token for the provided ``Resource``.
    case token(Resource)
}
