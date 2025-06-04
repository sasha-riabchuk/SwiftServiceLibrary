import Foundation

extension URL {
    public init?<T: ServiceProtocol>(service: T, baseUrl: URL? = nil) {
        guard let baseUrl = baseUrl ?? service.baseURL else {
            return nil
        }
        guard let servicePath = service.path, !servicePath.isEmpty else {
            self = baseUrl
            return
        }
        self = baseUrl.appendingPathComponent(servicePath)
    }

    func appending(parameters: [String: Any]) -> URL {
        appendingLegacy(queryItems: parameters.compactMap { URLQueryItem(name: $0.key, value: "\($0.value)") })
    }
}

extension URL {
    // Fallback on earlier versions
    func appendingLegacy(queryItems: [URLQueryItem]) -> URL {
        if #available(iOS 16.0, macOS 13.0, *) {
            return appending(queryItems: queryItems)
        } else {
            // Fallback on earlier versions
            guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
                return self
            }
            urlComponents.queryItems = (urlComponents.queryItems ?? []) + queryItems
            return urlComponents.url ?? self
        }
    }

    func appendingLegacy(path: String) -> URL {
        if #available(iOS 16.0, macOS 13.0, *) {
            return appending(path: path)
        } else {
            // Fallback on earlier versions
            guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
                return self
            }
            urlComponents.path = path
            return urlComponents.url ?? self
        }
    }
}
