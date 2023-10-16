# ServiceLibrary

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

