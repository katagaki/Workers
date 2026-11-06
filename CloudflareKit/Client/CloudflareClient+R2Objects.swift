import Foundation

public extension CloudflareClient {
    // Wrangler enforces the same cap on single request uploads through this API.
    static let r2UploadLimit = 300 * 1024 * 1024

    func r2ObjectExists(accountId: String, bucketName: String, key: String) async throws -> Bool {
        try await r2ExistingObject(accountId: accountId, bucketName: bucketName, key: key) != nil
    }

    func r2DownloadObject(accountId: String, bucketName: String, key: String) async throws -> R2DownloadedObject {
        let request = try rawRequest(.get, path: r2ObjectsPath(accountId, bucketName), pathComponent: key)
        let (downloadedURL, response) = try await session.download(for: request)
        defer { try? FileManager.default.removeItem(at: downloadedURL) }
        try validateRawResponse(response, data: (try? Data(contentsOf: downloadedURL)) ?? Data())
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("R2Downloads", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent(Self.r2FileName(for: key))
        try FileManager.default.moveItem(at: downloadedURL, to: fileURL)
        let fields = (response as? HTTPURLResponse)?.allHeaderFields ?? [:]
        var headers: [String: String] = [:]
        for (name, value) in fields {
            if let name = name as? String, let value = value as? String {
                headers[name.lowercased()] = value
            }
        }
        return R2DownloadedObject(fileURL: fileURL, headers: headers)
    }

    func r2UploadObject(
        accountId: String,
        bucketName: String,
        key: String,
        fileURL: URL,
        contentType: String?
    ) async throws {
        var headers: [String: String] = [:]
        if let contentType {
            headers["Content-Type"] = contentType
        }
        try await r2Put(accountId: accountId, bucketName: bucketName, key: key, fileURL: fileURL, headers: headers)
    }

    func r2CreateFolder(accountId: String, bucketName: String, prefix: String) async throws {
        var request = try rawRequest(.put, path: r2ObjectsPath(accountId, bucketName), pathComponent: prefix)
        request.setValue("0", forHTTPHeaderField: "Content-Length")
        let (data, response) = try await session.upload(for: request, from: Data())
        try validateRawResponse(response, data: data)
    }

    func r2DeleteObject(accountId: String, bucketName: String, key: String) async throws {
        let request = try rawRequest(.delete, path: r2ObjectsPath(accountId, bucketName), pathComponent: key)
        let (data, response) = try await session.data(for: request)
        if (response as? HTTPURLResponse)?.statusCode == 404 { return }
        try validateRawResponse(response, data: data)
    }

    func r2DeleteFolder(
        accountId: String,
        bucketName: String,
        prefix: String,
        progress: @MainActor @Sendable (Int, Int) -> Void = { _, _ in }
    ) async throws {
        guard !prefix.isEmpty else { throw CloudflareError.invalidResponse }
        let objects = try await r2AllObjects(accountId: accountId, bucketName: bucketName, prefix: prefix)
        for (index, object) in objects.enumerated() {
            try Task.checkCancellation()
            await progress(index, objects.count)
            try await r2DeleteObject(accountId: accountId, bucketName: bucketName, key: object.key)
        }
    }

    func r2RenameObject(accountId: String, bucketName: String, object: R2Object, newKey: String) async throws {
        try Self.validateRenamable(object)
        if try await r2ObjectExists(accountId: accountId, bucketName: bucketName, key: newKey) {
            throw CloudflareError.r2KeyExists(key: newKey)
        }
        try await r2Move(accountId: accountId, bucketName: bucketName, object: object, newKey: newKey)
    }

    func r2RenameFolder(
        accountId: String,
        bucketName: String,
        prefix: String,
        newPrefix: String,
        progress: @MainActor @Sendable (Int, Int) -> Void = { _, _ in }
    ) async throws {
        guard !prefix.isEmpty, !newPrefix.isEmpty, !newPrefix.hasPrefix(prefix) else {
            throw CloudflareError.invalidResponse
        }
        let existing = try await r2Objects(
            accountId: accountId,
            bucketName: bucketName,
            prefix: newPrefix,
            limit: 1,
            delimiter: nil
        )
        guard existing.objects.isEmpty else { throw CloudflareError.r2KeyExists(key: newPrefix) }
        let objects = try await r2AllObjects(accountId: accountId, bucketName: bucketName, prefix: prefix)
        try objects.forEach(Self.validateRenamable)
        for (index, object) in objects.enumerated() {
            try Task.checkCancellation()
            await progress(index, objects.count)
            let newKey = newPrefix + object.key.dropFirst(prefix.count)
            try await r2Move(accountId: accountId, bucketName: bucketName, object: object, newKey: newKey)
        }
    }
}

private extension CloudflareClient {
    static let r2PreservedHeaders = ["cache-control", "content-disposition", "content-encoding", "content-language", "expires"]

    func r2ObjectsPath(_ accountId: String, _ bucketName: String) -> String {
        "accounts/\(accountId)/r2/buckets/\(bucketName)/objects"
    }

    static func r2FileName(for key: String) -> String {
        let lastComponent = key.split(separator: "/").last.map(String.init) ?? ""
        return lastComponent.isEmpty ? "object" : lastComponent.replacingOccurrences(of: ":", with: "_")
    }

    // The object API has no way to write custom metadata, so a copy would silently lose it.
    static func validateRenamable(_ object: R2Object) throws {
        if object.customMetadata?.isEmpty == false {
            throw CloudflareError.r2CustomMetadataUnsupported(key: object.key)
        }
        if let size = object.size, size > r2UploadLimit {
            throw CloudflareError.r2ObjectTooLarge(key: object.key, limit: r2UploadLimit)
        }
    }

    func r2ExistingObject(accountId: String, bucketName: String, key: String) async throws -> R2Object? {
        let page = try await r2Objects(accountId: accountId, bucketName: bucketName, prefix: key, limit: 1)
        return page.objects.first { $0.key == key }
    }

    func r2AllObjects(accountId: String, bucketName: String, prefix: String) async throws -> [R2Object] {
        var objects: [R2Object] = []
        var cursor: String?
        repeat {
            try Task.checkCancellation()
            let page = try await r2Objects(
                accountId: accountId,
                bucketName: bucketName,
                prefix: prefix,
                cursor: cursor,
                limit: 1000,
                delimiter: nil
            )
            objects += page.objects
            cursor = page.nextCursor
        } while cursor != nil
        return objects
    }

    func r2Put(
        accountId: String,
        bucketName: String,
        key: String,
        fileURL: URL,
        headers: [String: String]
    ) async throws {
        let fileSize = try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard fileSize <= Self.r2UploadLimit else {
            throw CloudflareError.r2ObjectTooLarge(key: key, limit: Self.r2UploadLimit)
        }
        var request = try rawRequest(.put, path: r2ObjectsPath(accountId, bucketName), pathComponent: key)
        request.setValue(String(fileSize), forHTTPHeaderField: "Content-Length")
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }
        let (data, response) = try await session.upload(for: request, fromFile: fileURL)
        try validateRawResponse(response, data: data)
    }

    // R2 has no copy or rename here, so the source is only deleted once the listing confirms the copy.
    func r2Move(accountId: String, bucketName: String, object: R2Object, newKey: String) async throws {
        let download = try await r2DownloadObject(accountId: accountId, bucketName: bucketName, key: object.key)
        defer { download.removeTemporaryFile() }
        // URLSession transparently decodes compressed objects, which would store different bytes.
        let downloadedSize = try download.fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize
        guard let expectedSize = object.size, downloadedSize == expectedSize else {
            throw CloudflareError.r2CopyVerificationFailed(key: object.key)
        }
        var headers: [String: String] = [:]
        for name in Self.r2PreservedHeaders {
            headers[name] = download.headers[name]
        }
        headers["Content-Type"] = object.httpMetadata?.contentType ?? download.headers["content-type"]
        headers["cf-r2-storage-class"] = object.storageClass
        try Task.checkCancellation()
        try await r2Put(
            accountId: accountId,
            bucketName: bucketName,
            key: newKey,
            fileURL: download.fileURL,
            headers: headers
        )
        let copy = try await r2ExistingObject(accountId: accountId, bucketName: bucketName, key: newKey)
        guard copy?.size == expectedSize else {
            throw CloudflareError.r2CopyVerificationFailed(key: object.key)
        }
        try await r2DeleteObject(accountId: accountId, bucketName: bucketName, key: object.key)
    }
}
