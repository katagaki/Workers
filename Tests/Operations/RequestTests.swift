import Foundation

final class RequestFixtures: @unchecked Sendable {
    static let shared = RequestFixtures()
    private let lock = NSLock()
    private var responses: [(Int, Data)] = []
    private var requests: [URLRequest] = []

    func enqueue(status: Int = 200, json: String) {
        lock.withLock { responses.append((status, Data(json.utf8))) }
    }

    func receive(_ request: URLRequest) -> (Int, Data) {
        lock.withLock {
            var captured = request
            if captured.httpBody == nil, let stream = captured.httpBodyStream {
                stream.open()
                defer { stream.close() }
                var data = Data()
                var buffer = [UInt8](repeating: 0, count: 4096)
                while stream.hasBytesAvailable {
                    let count = stream.read(&buffer, maxLength: buffer.count)
                    if count <= 0 { break }
                    data.append(buffer, count: count)
                }
                captured.httpBody = data
            }
            requests.append(captured)
            precondition(!responses.isEmpty, "Unexpected request")
            return responses.removeFirst()
        }
    }

    var lastRequest: URLRequest { lock.withLock { requests.last! } }
    var allRequests: [URLRequest] { lock.withLock { requests } }
    var pendingResponseCount: Int { lock.withLock { responses.count } }
}

final class FixtureProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}
    override func startLoading() {
        let (status, data) = RequestFixtures.shared.receive(request)
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
}

@main
struct OperationTests {
    static func main() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureProtocol.self]
        let client = CloudflareClient(token: "fixture-only", session: URLSession(configuration: configuration))
        let fixtures = RequestFixtures.shared
        fixtures.enqueue(json: #"{"success":true,"result":{"id":"deployment","created_on":"2026-10-11T01:00:00Z","versions":[{"version_id":"first","percentage":90},{"version_id":"second","percentage":10}]}}"#)
        let deployment = try await client.deployWorkerVersions(accountId: "account", scriptName: "script", versions: [
            .init(versionId: "first", percentage: 90), .init(versionId: "second", percentage: 10)
        ])
        precondition(deployment.versions.count == 2)
        precondition(fixtures.lastRequest.httpMethod == "POST")
        precondition(fixtures.lastRequest.url?.path == "/client/v4/accounts/account/workers/scripts/script/deployments")
        let body = try JSONSerialization.jsonObject(with: fixtures.lastRequest.httpBody!) as! [String: Any]
        precondition(body["strategy"] as? String == "percentage")
        precondition(body["force"] == nil)
        let versions = body["versions"] as! [[String: Any]]
        precondition(versions.first?["version_id"] as? String == "first")
        precondition(versions.last?["percentage"] as? Double == 10)
        do {
            _ = try await client.deployWorkerVersions(accountId: "account", scriptName: "script", versions: [.init(versionId: "first", percentage: 90)])
            preconditionFailure("Invalid traffic allocation must be rejected before networking")
        } catch CloudflareError.invalidResponse {}
        fixtures.enqueue(status: 403, json: "{}")
        do {
            _ = try await client.deployWorkerVersions(accountId: "account", scriptName: "script", versions: [.init(versionId: "first", percentage: 100)])
            preconditionFailure("Permission errors must propagate")
        } catch CloudflareError.http(let statusCode) { precondition(statusCode == 403) }
        fixtures.enqueue(json: #"{"success":true,"result":[{"id":"model","name":"@cf/test/text","task":{"name":"Text Generation"}}]}"#)
        let models = try await client.aiTextModels(accountId: "account")
        precondition(models.first?.name == "@cf/test/text")
        let query = URLComponents(url: fixtures.lastRequest.url!, resolvingAgainstBaseURL: false)!.queryItems!
        precondition(query.contains { $0.name == "task" && $0.value == "Text Generation" })
        fixtures.enqueue(json: #"{"success":true,"result":{"input":{"oneOf":[{"properties":{"prompt":{"type":"string"},"stream":{"type":"boolean"}}}]},"output":{}}}"#)
        let schema = try await client.aiModelSchema(accountId: "account", modelName: "@cf/test/text")
        precondition(schema.supports("prompt") && schema.supports("stream"))
        precondition(!schema.supports("messages"))
        fixtures.enqueue(json: #"{"success":true,"result":{"response":"Generated text"}}"#)
        let generated = try await client.runAIText(accountId: "account", modelName: "@cf/test/text", input: ["prompt": .string("Hello"), "max_tokens": .number(128)])
        precondition(generated == "Generated text")
        precondition(fixtures.lastRequest.url?.path == "/client/v4/accounts/account/ai/run/@cf/test/text")
        let input = try JSONSerialization.jsonObject(with: fixtures.lastRequest.httpBody!) as! [String: Any]
        precondition(input["prompt"] as? String == "Hello" && input["max_tokens"] as? Int == 128)
        fixtures.enqueue(json: "data: {\"response\":\"Hello \"}\n\ndata: {\"response\":\"world\"}\n\ndata: [DONE]\n\n")
        var streamed = ""
        for try await chunk in client.streamAIText(accountId: "account", modelName: "@cf/test/text", input: ["prompt": .string("Hello")]) {
            streamed += chunk
        }
        precondition(streamed == "Hello world")
        fixtures.enqueue(json: #"{"success":true,"result":{"value":"under_attack","editable":true}}"#)
        let security = try await client.setZoneUnderAttack(zoneId: "zone", enabled: true)
        precondition(security.isUnderAttack)
        precondition(fixtures.lastRequest.httpMethod == "PATCH")
        precondition(fixtures.lastRequest.url?.path == "/client/v4/zones/zone/settings/security_level")
        fixtures.enqueue(json: #"{"success":true,"result":{"value":"high","editable":true}}"#)
        _ = try await client.setZoneUnderAttack(zoneId: "zone", enabled: false, restoredLevel: "high")
        let restoredBody = try JSONSerialization.jsonObject(with: fixtures.lastRequest.httpBody!) as! [String: Any]
        precondition(restoredBody["value"] as? String == "high")
        fixtures.enqueue(json: #"{"success":true,"result":{"id":"zone"}}"#)
        try await client.purgeURLs(zoneId: "zone", urls: [URL(string: "https://example.com/path?key=value")!])
        let purgeBody = try JSONSerialization.jsonObject(with: fixtures.lastRequest.httpBody!) as! [String: Any]
        precondition(purgeBody["files"] as? [String] == ["https://example.com/path?key=value"])
        precondition(purgeBody["purge_everything"] == nil)
        do {
            try await client.purgeURLs(zoneId: "zone", urls: [URL(string: "file:///tmp/test")!])
            preconditionFailure("Non-HTTP URLs must be rejected before networking")
        } catch CloudflareError.invalidResponse {}
        let demo = CloudflareClient.demo()
        let zones = try await demo.zones(accountId: "8d2c4f1e9a7b4c3d5e6f708192a3b4c5")
        let zoneID = zones[0].id
        _ = try await demo.setZonePaused(zoneId: zoneID, paused: true)
        let paused = try await demo.zone(id: zoneID)
        precondition(paused.paused == true)
        _ = try await demo.setZoneUnderAttack(zoneId: zoneID, enabled: true)
        let attacked = try await demo.zoneSecurityLevel(zoneId: zoneID)
        precondition(attacked.isUnderAttack)
        _ = try await demo.setZoneUnderAttack(zoneId: zoneID, enabled: false, restoredLevel: "high")
        let restored = try await demo.zoneSecurityLevel(zoneId: zoneID)
        precondition(restored.value == "high")
        try await testR2Requests(client: client, fixtures: fixtures)
        try await testR2Demo(demo: demo)
        print("Operation request tests passed")
    }

    private static func r2Listing(_ objects: String = "") -> String {
        #"{"success":true,"result":["# + objects + #"],"result_info":{"is_truncated":false,"delimited":[]}}"#
    }

    private static func r2Object(key: String, size: Int, extra: String = "") -> R2Object {
        let json = #"{"key":"\#(key)","size":\#(size),"storage_class":"InfrequentAccess","http_metadata":{"contentType":"text/plain"}\#(extra)}"#
        return try! CloudflareJSON.makeDecoder().decode(R2Object.self, from: Data(json.utf8))
    }

    private static func testR2Requests(client: CloudflareClient, fixtures: RequestFixtures) async throws {
        let objectsPath = "/client/v4/accounts/account/r2/buckets/bucket/objects"
        func deletes() -> [URLRequest] { fixtures.allRequests.filter { $0.httpMethod == "DELETE" } }

        fixtures.enqueue(json: #"{"success":true,"result":null}"#)
        try await client.r2DeleteObject(accountId: "account", bucketName: "bucket", key: "folder/a b.txt")
        precondition(fixtures.lastRequest.httpMethod == "DELETE")
        precondition(fixtures.lastRequest.url?.absoluteString.hasSuffix("/objects/folder%2Fa%20b.txt") == true, "Keys must stay one path component")

        fixtures.enqueue(status: 404, json: #"{"success":false,"errors":[{"code":10007,"message":"not found"}]}"#)
        try await client.r2DeleteObject(accountId: "account", bucketName: "bucket", key: "gone.txt")

        fixtures.enqueue(status: 403, json: "{}")
        do {
            try await client.r2DeleteObject(accountId: "account", bucketName: "bucket", key: "denied.txt")
            preconditionFailure("A read only token must surface a permission error")
        } catch CloudflareError.http(statusCode: 403) {}

        do {
            try await client.r2DeleteFolder(accountId: "account", bucketName: "bucket", prefix: "")
            preconditionFailure("An empty prefix must never delete a whole bucket")
        } catch CloudflareError.invalidResponse {}

        let deleteCount = deletes().count
        fixtures.enqueue(json: #"{"success":true,"result":[{"key":"folder/"},{"key":"folder/a.txt"}],"result_info":{"is_truncated":true,"cursor":"next"}}"#)
        fixtures.enqueue(json: #"{"success":true,"result":[{"key":"folder/deep/b.txt"}],"result_info":{"is_truncated":false}}"#)
        for _ in 0..<3 { fixtures.enqueue(json: #"{"success":true,"result":null}"#) }
        try await client.r2DeleteFolder(accountId: "account", bucketName: "bucket", prefix: "folder/")
        precondition(deletes().count == deleteCount + 3, "Folder deletes must follow every listing page")
        let listRequest = fixtures.allRequests[fixtures.allRequests.count - 5]
        precondition(listRequest.url?.query?.contains("delimiter") == false, "Folder listings must be recursive")

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("upload.txt")
        try Data("hello".utf8).write(to: fileURL)
        fixtures.enqueue(json: #"{"success":true,"result":{}}"#)
        try await client.r2UploadObject(accountId: "account", bucketName: "bucket", key: "a/upload.txt", fileURL: fileURL, contentType: "text/plain")
        precondition(fixtures.lastRequest.httpMethod == "PUT")
        precondition(fixtures.lastRequest.value(forHTTPHeaderField: "Content-Type") == "text/plain")
        precondition(fixtures.lastRequest.value(forHTTPHeaderField: "Content-Length") == "5")

        let uploadRequest = try client.r2UploadRequest(accountId: "account", bucketName: "bucket", key: "a/big.bin", fileSize: CloudflareClient.r2UploadLimit, contentType: "video/mp4")
        precondition(uploadRequest.httpMethod == "PUT" && uploadRequest.url?.absoluteString.hasSuffix("/objects/a%2Fbig.bin") == true)
        precondition(uploadRequest.value(forHTTPHeaderField: "Authorization") == "Bearer fixture-only")
        precondition(uploadRequest.value(forHTTPHeaderField: "Content-Length") == "300000000")
        do {
            _ = try client.r2UploadRequest(accountId: "account", bucketName: "bucket", key: "huge.bin", fileSize: CloudflareClient.r2UploadLimit + 1, contentType: nil)
            preconditionFailure("Uploads above the limit must be refused before networking")
        } catch CloudflareError.r2ObjectTooLarge {}
        precondition(CloudflareError.r2ObjectTooLarge(key: "huge.bin", limit: CloudflareClient.r2UploadLimit).errorDescription?.contains("300 MB") == true)

        fixtures.enqueue(json: #"{"success":true,"result":{}}"#)
        try await client.r2CreateFolder(accountId: "account", bucketName: "bucket", prefix: "new/")
        precondition(fixtures.lastRequest.url?.absoluteString.hasSuffix("/objects/new%2F") == true)

        let source = r2Object(key: "a.txt", size: 5)
        var deleteTotal = deletes().count
        fixtures.enqueue(json: r2Listing())
        fixtures.enqueue(json: "hello")
        fixtures.enqueue(json: #"{"success":true,"result":{}}"#)
        fixtures.enqueue(json: r2Listing(#"{"key":"b.txt","size":5}"#))
        fixtures.enqueue(json: #"{"success":true,"result":null}"#)
        try await client.r2RenameObject(accountId: "account", bucketName: "bucket", object: source, newKey: "b.txt")
        let put = fixtures.allRequests.last { $0.httpMethod == "PUT" }!
        precondition(put.url?.path == objectsPath + "/b.txt")
        precondition(put.value(forHTTPHeaderField: "cf-r2-storage-class") == "InfrequentAccess", "Rename must keep the storage class")
        precondition(put.value(forHTTPHeaderField: "Content-Type") == "text/plain", "Rename must keep the content type")
        precondition(fixtures.lastRequest.httpMethod == "DELETE" && fixtures.lastRequest.url?.path == objectsPath + "/a.txt")
        deleteTotal += 1
        precondition(deletes().count == deleteTotal)

        fixtures.enqueue(json: r2Listing(#"{"key":"b.txt","size":1}"#))
        do {
            try await client.r2RenameObject(accountId: "account", bucketName: "bucket", object: source, newKey: "b.txt")
            preconditionFailure("Rename must not overwrite an existing object")
        } catch CloudflareError.r2KeyExists {}

        fixtures.enqueue(json: r2Listing())
        fixtures.enqueue(json: "decompressed to a different size")
        do {
            try await client.r2RenameObject(accountId: "account", bucketName: "bucket", object: source, newKey: "b.txt")
            preconditionFailure("A changed download must stop the rename")
        } catch CloudflareError.r2CopyVerificationFailed {}

        fixtures.enqueue(json: r2Listing())
        fixtures.enqueue(json: "hello")
        fixtures.enqueue(status: 500, json: #"{"success":false,"errors":[{"message":"upload failed"}]}"#)
        do {
            try await client.r2RenameObject(accountId: "account", bucketName: "bucket", object: source, newKey: "b.txt")
            preconditionFailure("A failed upload must stop the rename")
        } catch CloudflareError.api {}

        fixtures.enqueue(json: r2Listing())
        fixtures.enqueue(json: "hello")
        fixtures.enqueue(json: #"{"success":true,"result":{}}"#)
        fixtures.enqueue(json: r2Listing())
        do {
            try await client.r2RenameObject(accountId: "account", bucketName: "bucket", object: source, newKey: "b.txt")
            preconditionFailure("An unconfirmed copy must stop the rename")
        } catch CloudflareError.r2CopyVerificationFailed {}
        precondition(deletes().count == deleteTotal, "A failed rename must never delete the source")

        let customized = r2Object(key: "c.txt", size: 5, extra: #","custom_metadata":{"owner":"seminar"}"#)
        do {
            try await client.r2RenameObject(accountId: "account", bucketName: "bucket", object: customized, newKey: "d.txt")
            preconditionFailure("Rename must not lose custom metadata")
        } catch CloudflareError.r2CustomMetadataUnsupported {}

        fixtures.enqueue(json: r2Listing())
        fixtures.enqueue(json: r2Listing(#"{"key":"old/a.txt","size":5},{"key":"old/b.txt","size":5,"custom_metadata":{"owner":"seminar"}}"#))
        do {
            try await client.r2RenameFolder(accountId: "account", bucketName: "bucket", prefix: "old/", newPrefix: "new/")
            preconditionFailure("Folder rename must check every object before moving any")
        } catch CloudflareError.r2CustomMetadataUnsupported {}

        fixtures.enqueue(json: r2Listing(#"{"key":"new/a.txt","size":5}"#))
        do {
            try await client.r2RenameFolder(accountId: "account", bucketName: "bucket", prefix: "old/", newPrefix: "new/")
            preconditionFailure("Folder rename must not merge into an existing folder")
        } catch CloudflareError.r2KeyExists {}
        precondition(deletes().count == deleteTotal && fixtures.pendingResponseCount == 0)

        fixtures.enqueue(json: "object body")
        let download = try await client.r2DownloadObject(accountId: "account", bucketName: "bucket", key: "folder/report.txt")
        precondition(download.fileURL.lastPathComponent == "report.txt")
        let downloadedData = try Data(contentsOf: download.fileURL)
        precondition(downloadedData == Data("object body".utf8))
        download.removeTemporaryFile()
        precondition(!FileManager.default.fileExists(atPath: download.fileURL.path))

        fixtures.enqueue(status: 404, json: #"{"success":false,"errors":[{"message":"object missing"}]}"#)
        do {
            _ = try await client.r2DownloadObject(accountId: "account", bucketName: "bucket", key: "missing.txt")
            preconditionFailure("A failed download must not produce a file")
        } catch CloudflareError.api(let messages) { precondition(messages == ["object missing"]) }
    }

    private static func testR2Demo(demo: CloudflareClient) async throws {
        let account = "demo"
        let bucket = "originals"
        let root = try await demo.r2Objects(accountId: account, bucketName: bucket)
        let readme = root.objects.first { $0.key == "README.txt" }!
        try await demo.r2RenameObject(accountId: account, bucketName: bucket, object: readme, newKey: "RENAMED.txt")
        let renamedExists = try await demo.r2ObjectExists(accountId: account, bucketName: bucket, key: "RENAMED.txt")
        let originalExists = try await demo.r2ObjectExists(accountId: account, bucketName: bucket, key: "README.txt")
        precondition(renamedExists && !originalExists)
        try await demo.r2RenameFolder(accountId: account, bucketName: bucket, prefix: "students/", newPrefix: "pupils/")
        let pupils = try await demo.r2Objects(accountId: account, bucketName: bucket, prefix: "pupils/")
        precondition(pupils.objects.count == 3)
        try await demo.r2DeleteFolder(accountId: account, bucketName: bucket, prefix: "pupils/")
        try await demo.r2CreateFolder(accountId: account, bucketName: bucket, prefix: "empty/")
        let updated = try await demo.r2Objects(accountId: account, bucketName: bucket)
        precondition(updated.folders.sorted() == ["empty/", "notices/"])
    }
}
