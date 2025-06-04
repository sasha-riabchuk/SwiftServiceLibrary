/// Describes a service capable of providing authorization configuration.
public protocol ServiceProtocolAuthorizable {
    /// Returns the ``AuthorizableType`` required by the service.
    func authorizableType() -> AuthorizableType
}
