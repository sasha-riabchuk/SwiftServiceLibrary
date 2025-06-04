/// A protocol describing an object that may require an access token for a specific resource.
public protocol AccessTokenAuthorizable {
    /// Optional identifier for a protected resource.
    var resourceID: String? { get }
}
