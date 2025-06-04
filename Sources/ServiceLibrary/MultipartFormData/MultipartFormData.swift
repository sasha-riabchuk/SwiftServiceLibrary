import Foundation

#if os(iOS) || os(watchOS) || os(tvOS)
    import MobileCoreServices
#elseif os(macOS)
    import CoreServices
#endif

/// Constructs `multipart/form-data` for uploads within an HTTP or HTTPS body. There are currently two ways to encode
/// multipart form data. The first way is to encode the data directly in memory. This is very efficient, but can lead
/// to memory issues if the dataset is too large. The second way is designed for larger datasets and will write all the
/// data to a single file on disk with all the proper boundary segmentation. The second approach MUST be used for
/// larger datasets such as video content, otherwise your app may run out of memory when trying to encode the dataset.
///
/// For more information on `multipart/form-data` in general, please refer to the RFC-2388 and RFC-2045 specs as well
/// and the w3 form documentation.
///
/// - https://www.ietf.org/rfc/rfc2388.txt
/// - https://www.ietf.org/rfc/rfc2045.txt
/// - https://www.w3.org/TR/html401/interact/forms.html#h-17.13
open class MultipartFormData {
    // MARK: - Helper Types

    enum EncodingCharacters {
        static let crlf = "\r\n"
    }

    class BodyPart {
        let headers: HTTPHeaders
        let bodyStream: InputStream
        let bodyContentLength: UInt64
        var hasInitialBoundary = false
        var hasFinalBoundary = false

        init(headers: HTTPHeaders, bodyStream: InputStream, bodyContentLength: UInt64) {
            self.headers = headers
            self.bodyStream = bodyStream
            self.bodyContentLength = bodyContentLength
        }
    }

    // MARK: - Properties

    /// Default memory threshold used when encoding `MultipartFormData`, in bytes.
    public static let encodingMemoryThreshold: UInt64 = 10_000_000

    /// The `Content-Type` header value containing the boundary used to generate the `multipart/form-data`.
    open lazy var contentType: String = "multipart/form-data; boundary=\(self.boundary)"

    /// The content length of all body parts used to generate the `multipart/form-data` not including the boundaries.
    public var contentLength: UInt64 { bodyParts.reduce(0) { $0 + $1.bodyContentLength } }

    /// The boundary used to separate the body parts in the encoded form data.
    public let boundary: String
    private var bodyParts: [BodyPart]
    private let streamBufferSize: Int

    // MARK: - Lifecycle

    /// Creates an instance.
    ///
    /// - Parameters:
    ///   - boundary: Boundary `String` used to separate body parts.
    public init(boundary: String? = nil) {
        self.boundary = boundary ?? BoundaryGenerator.randomBoundary()
        bodyParts = []

        //
        // The optimal read/write buffer size in bytes for input and output streams is 1024 (1KB). For more
        // information, please refer to the following article:
        // swiftlint:disable:next line_length
        // https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Streams/Articles/ReadingInputStreams.html
        //
        streamBufferSize = 1_024
    }

    // MARK: - Body Parts

    /// Creates a body part from the data and appends it to the instance.
    ///
    /// The body part data will be encoded using the following format:
    ///
    /// - `Content-Disposition: form-data; name=#{name}; filename=#{filename}` (HTTP Header)
    /// - `Content-Type: #{mimeType}` (HTTP Header)
    /// - Encoded file data
    /// - Multipart form boundary
    ///
    /// - Parameters:
    ///   - data:     `Data` to encoding into the instance.
    ///   - name:     Name to associate with the `Data` in the `Content-Disposition` HTTP header.
    ///   - fileName: Filename to associate with the `Data` in the `Content-Disposition` HTTP header.
    ///   - mimeType: MIME type to associate with the data in the `Content-Type` HTTP header.
    public func append(_ data: Data, withName name: String, fileName: String? = nil, mimeType: String? = nil) {
        let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
        let stream = InputStream(data: data)
        let length = UInt64(data.count)
        append(stream, withLength: length, headers: headers)
    }

    /// Creates a body part from the stream and appends it to the instance.
    ///
    /// The body part data will be encoded using the following format:
    ///
    /// - `Content-Disposition: form-data; name=#{name}; filename=#{filename}` (HTTP Header)
    /// - `Content-Type: #{mimeType}` (HTTP Header)
    /// - Encoded stream data
    /// - Multipart form boundary
    ///
    /// - Parameters:
    ///   - stream:   `InputStream` to encode into the instance.
    ///   - length:   Length, in bytes, of the stream.
    ///   - name:     Name to associate with the stream content in the `Content-Disposition` HTTP header.
    ///   - fileName: Filename to associate with the stream content in the `Content-Disposition` HTTP header.
    ///   - mimeType: MIME type to associate with the stream content in the `Content-Type` HTTP header.
    public func append(
        _ stream: InputStream,
        withLength length: UInt64,
        name: String,
        fileName: String,
        mimeType: String
    ) {
        let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
        append(stream, withLength: length, headers: headers)
    }

    /// Creates a body part with the stream, length, and headers and appends it to the instance.
    ///
    /// The body part data will be encoded using the following format:
    ///
    /// - HTTP headers
    /// - Encoded stream data
    /// - Multipart form boundary
    ///
    /// - Parameters:
    ///   - stream:  `InputStream` to encode into the instance.
    ///   - length:  Length, in bytes, of the stream.
    ///   - headers: `HTTPHeaders` for the body part.
    public func append(_ stream: InputStream, withLength length: UInt64, headers: HTTPHeaders) {
        let bodyPart = BodyPart(headers: headers, bodyStream: stream, bodyContentLength: length)
        bodyParts.append(bodyPart)
    }

    // MARK: - Data Encoding

    /// Encodes all appended body parts into a single `Data` value.
    ///
    /// - Note: This method will load all the appended body parts into memory all at the same time. This method should
    ///         only be used when the encoded data will have a small memory footprint. For large data cases, please use
    ///         the `writeEncodedData(to:))` method.
    ///
    /// - Returns: The encoded `Data`, if encoding is successful.
    /// - Throws:  An `AFError` if encoding encounters an error.
    public func encode() throws -> Data {
        var encoded = Data()

        bodyParts.first?.hasInitialBoundary = true
        bodyParts.last?.hasFinalBoundary = true

        for bodyPart in bodyParts {
            let encodedData = try encode(bodyPart)
            encoded.append(encodedData)
        }

        return encoded
    }

    // MARK: - Private - Body Part Encoding

    private func encode(_ bodyPart: BodyPart) throws -> Data {
        var encoded = Data()

        let initialData = bodyPart.hasInitialBoundary ? initialBoundaryData() : encapsulatedBoundaryData()
        encoded.append(initialData)

        let headerData = encodeHeaders(for: bodyPart)
        encoded.append(headerData)

        let bodyStreamData = try encodeBodyStream(for: bodyPart)
        encoded.append(bodyStreamData)

        if bodyPart.hasFinalBoundary {
            encoded.append(finalBoundaryData())
        }

        return encoded
    }

    private func encodeHeaders(for bodyPart: BodyPart) -> Data {
        let headerText = bodyPart.headers.map { "\($0.name): \($0.value)\(EncodingCharacters.crlf)" }
            .joined()
            + EncodingCharacters.crlf

        return Data(headerText.utf8)
    }

    private func encodeBodyStream(for bodyPart: BodyPart) throws -> Data {
        let inputStream = bodyPart.bodyStream
        inputStream.open()
        defer { inputStream.close() }

        var encoded = Data()

        while inputStream.hasBytesAvailable {
            var buffer = [UInt8](repeating: 0, count: streamBufferSize)
            let bytesRead = inputStream.read(&buffer, maxLength: streamBufferSize)

            if let error = inputStream.streamError {
                throw MultipartEncodingError.inputStreamReadFailed(error: error)
            }

            if bytesRead > 0 {
                encoded.append(buffer, count: bytesRead)
            } else {
                break
            }
        }

        guard UInt64(encoded.count) == bodyPart.bodyContentLength else {
            throw MultipartEncodingError.unexpectedInputStreamLength(
                bytesExpected: bodyPart.bodyContentLength,
                bytesRead: UInt64(encoded.count)
            )
        }

        return encoded
    }

    // MARK: - Private - Writing Body Part to Output Stream

    private func write(_ bodyPart: BodyPart, to outputStream: OutputStream) throws {
        try writeInitialBoundaryData(for: bodyPart, to: outputStream)
        try writeHeaderData(for: bodyPart, to: outputStream)
        try writeBodyStream(for: bodyPart, to: outputStream)
        try writeFinalBoundaryData(for: bodyPart, to: outputStream)
    }

    private func writeInitialBoundaryData(for bodyPart: BodyPart, to outputStream: OutputStream) throws {
        let initialData = bodyPart.hasInitialBoundary ? initialBoundaryData() : encapsulatedBoundaryData()
        return try write(initialData, to: outputStream)
    }

    private func writeHeaderData(for bodyPart: BodyPart, to outputStream: OutputStream) throws {
        let headerData = encodeHeaders(for: bodyPart)
        return try write(headerData, to: outputStream)
    }

    private func writeBodyStream(for bodyPart: BodyPart, to outputStream: OutputStream) throws {
        let inputStream = bodyPart.bodyStream

        inputStream.open()
        defer { inputStream.close() }

        while inputStream.hasBytesAvailable {
            var buffer = [UInt8](repeating: 0, count: streamBufferSize)
            let bytesRead = inputStream.read(&buffer, maxLength: streamBufferSize)

            if let streamError = inputStream.streamError {
                throw MultipartEncodingError.inputStreamReadFailed(error: streamError)
            }

            if bytesRead > 0 {
                if buffer.count != bytesRead {
                    buffer = Array(buffer[0 ..< bytesRead])
                }

                try write(&buffer, to: outputStream)
            } else {
                break
            }
        }
    }

    private func writeFinalBoundaryData(for bodyPart: BodyPart, to outputStream: OutputStream) throws {
        if bodyPart.hasFinalBoundary {
            return try write(finalBoundaryData(), to: outputStream)
        }
    }

    // MARK: - Private - Writing Buffered Data to Output Stream

    private func write(_ data: Data, to outputStream: OutputStream) throws {
        var buffer = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &buffer, count: data.count)

        return try write(&buffer, to: outputStream)
    }

    private func write(_ buffer: inout [UInt8], to outputStream: OutputStream) throws {
        var bytesToWrite = buffer.count

        while bytesToWrite > 0, outputStream.hasSpaceAvailable {
            let bytesWritten = outputStream.write(buffer, maxLength: bytesToWrite)

            if let error = outputStream.streamError {
                throw MultipartEncodingError.outputStreamWriteFailed(error: error)
            }

            bytesToWrite -= bytesWritten

            if bytesToWrite > 0 {
                buffer = Array(buffer[bytesWritten ..< buffer.count])
            }
        }
    }

    // MARK: - Private - Content Headers

    private func contentHeaders(
        withName name: String,
        fileName: String? = nil,
        mimeType: String? = nil
    ) -> HTTPHeaders {
        var disposition = "form-data; name=\"\(name)\""
        if let fileName = fileName { disposition += "; filename=\"\(fileName)\"" }

        var headers: HTTPHeaders = [.contentDisposition(disposition)]
        if let mimeType = mimeType { headers.add(.contentType(mimeType)) }

        return headers
    }

    // MARK: - Private - Boundary Encoding

    private func initialBoundaryData() -> Data {
        BoundaryGenerator.boundaryData(forBoundaryType: .initial, boundary: boundary)
    }

    private func encapsulatedBoundaryData() -> Data {
        BoundaryGenerator.boundaryData(forBoundaryType: .encapsulated, boundary: boundary)
    }

    private func finalBoundaryData() -> Data {
        BoundaryGenerator.boundaryData(forBoundaryType: .final, boundary: boundary)
    }
}

#if canImport(UniformTypeIdentifiers)
    import UniformTypeIdentifiers

    extension MultipartFormData {
        // MARK: - Private - Mime Type

        private func mimeType(forPathExtension pathExtension: String) -> String {
            if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
                return UTType(filenameExtension: pathExtension)?.preferredMIMEType ?? "application/octet-stream"
            } else {
                if let id = UTTypeCreatePreferredIdentifierForTag(
                    kUTTagClassFilenameExtension,
                    pathExtension as CFString, nil
                )?.takeRetainedValue(),
                    let contentType = UTTypeCopyPreferredTagWithClass(
                        id,
                        kUTTagClassMIMEType
                    )?.takeRetainedValue() {
                    return contentType as String
                }

                return "application/octet-stream"
            }
        }
    }

#else

    extension MultipartFormData {
        // MARK: - Private - Mime Type

        private func mimeType(forPathExtension pathExtension: String) -> String {
            #if !(os(Linux) || os(Windows))
                if let id = UTTypeCreatePreferredIdentifierForTag(
                    kUTTagClassFilenameExtension,
                    pathExtension as CFString, nil
                )?.takeRetainedValue(),

                    let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue() {
                    return contentType as String
                }
            #endif
            return "application/octet-stream"
        }
    }

#endif
