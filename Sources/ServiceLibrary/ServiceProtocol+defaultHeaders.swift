import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(CoreFoundation)
import CoreFoundation
#endif

extension ServiceProtocol {
    ///
    /// This function configures the content type of the request based on the encoding of the parameters
    /// and the specified string encoding.
    /// The content type could be either form url encoded or application/json.
    /// If the string encoding does not have a corresponding IANA character set name, "utf-8" is used as a fallback.
    ///
    /// - Parameters:
    ///   - encoding: The `String.Encoding` to use for the `Content-Type` header, defaults to `.utf8`.
    ///
    /// - Returns: A `HTTPHeaders` object configured with default headers
    /// and the `Content-Type header based on the parameters encoding
    /// and the specified string encoding.
    public func defaultHeaders(encoding: String.Encoding = .utf8) -> HTTPHeaders {
        let ianaName = encoding.ianaName ?? "utf-8"
        var headers = HTTPHeaders.default
        if let parametersEncoding {
            headers.add(.contentType("\(parametersEncoding.rawValue); charset=\(ianaName)"))
        }
        return headers
    }
}

extension String.Encoding {
    /// Returns the IANA character set name corresponding to the receiver's string encoding.
    ///
    /// IANA is an organization that manages global IP addressing,
    /// as well as many other Internet protocol-related symbols and numbers.
    /// They maintain a registry of all official character sets, each of which has a unique name.
    ///
    /// This method uses `CFStringConvertNSStringEncodingToEncoding` to convert
    /// from `NSStringEncoding` to `CFStringEncoding`, and `CFStringConvertEncodingToIANACharSetName`
    /// to convert from `CFStringEncoding` to the IANA character set name.
    /// If the conversion fails, this method returns `nil`.
    ///
    /// - Returns: The IANA character set name as a `String` or `nil` if the conversion fails.
    public var ianaName: String? {
        let cfEnc = CFStringConvertNSStringEncodingToEncoding(rawValue)
        guard let ianaName = CFStringConvertEncodingToIANACharSetName(cfEnc) as? String else {
            return nil
        }
        return ianaName
    }
}
