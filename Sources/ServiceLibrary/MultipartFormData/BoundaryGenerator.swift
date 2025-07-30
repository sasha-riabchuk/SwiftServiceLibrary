import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum BoundaryGenerator: Sendable {
    typealias EncodingCharacters = MultipartFormData.EncodingCharacters

    enum BoundaryType: Sendable {
        case initial, encapsulated, final
    }

    static func randomBoundary() -> String {
        let first = UInt32.random(in: UInt32.min ... UInt32.max)
        let second = UInt32.random(in: UInt32.min ... UInt32.max)

        return String(format: "boundary.%08x%08x", first, second)
    }

    static func boundaryData(forBoundaryType boundaryType: BoundaryType, boundary: String) -> Data {
        let boundaryText: String

        switch boundaryType {
        case .initial:
            boundaryText = "--\(boundary)\(EncodingCharacters.crlf)"
        case .encapsulated:
            boundaryText = "\(EncodingCharacters.crlf)--\(boundary)\(EncodingCharacters.crlf)"
        case .final:
            boundaryText = "\(EncodingCharacters.crlf)--\(boundary)--\(EncodingCharacters.crlf)"
        }

        return Data(boundaryText.utf8)
    }
}
