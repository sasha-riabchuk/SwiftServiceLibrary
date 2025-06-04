/// A type used to define how a set of parameters are applied to a `URLRequest`.
public enum BodyParameterEncoding: String {
    /// Sets encoded query string result as the HTTP body of the URL request.
    case formUrlEncoded = "application/x-www-form-urlencoded"

    /// Encodes any JSON compatible object as the HTTP body of the URL request.
    case json = "application/json"
}
