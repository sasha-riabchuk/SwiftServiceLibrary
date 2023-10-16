# ServiceLibrary

### Example of api service implementation

```swift
enum KYCService {
    case status
    case questionnaire
}

extension KYCService: ServiceProtocol {
    var baseURL: URL? {
        URL(string: "https://www.csast.csas.cz")
    }

    var path: String? {
        switch self {
        case .status:
            return "/webapi/api/v1/kyck/info"
        case .questionnaire:
            return "/webapi/api/v1/kyck/questionnaire"
        }
    }

    var httpMethod: ServiceLibrary.HttpMethod {
        switch self {
        case .status:
            return .get
        case .questionnaire:
            return .get
        }
    }

    var headers: [String: String]? {
        nil
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .status, .questionnaire:
            return nil
        }
    }

    var parameters: [String: Any]? {
        nil
    }

    var parametersEncoding: ServiceLibrary.BodyParameterEncoding {
        .json
    }
}

```
### Example of using the api service

```swift
    let kycInfo: KYCInfo = try await KYCService.status.perform()
```

### Example of using the api service

```swift
    let service = KycService.attachments
    let imageData = UIImage(systemName: "person")?.pngData() ?? Data()
    let multipartFormData = MultipartFormData()

    multipartFormData.append(imageData, withName: "image1" , fileName: "person.png", mimeType: "image/png")
    multipartFormData.append(imageData, withName: "image2" , fileName: "person2.png", mimeType: "image/png")
    
    let parameters: [String: String] = ["name": "Johnny Applesee", "gender": "Male"]

    for (key, value) in parameters {
        multipartFormData.append(value.data(using: .utf8) ?? Data(), withName: key)
    }

    let string: String = try await service
        .performUpload(multipartFormData: multipartFormData,
                       handleResponse: { data, URLResponse in
            String(data: data, encoding: .utf8) ?? ""
        })
```

