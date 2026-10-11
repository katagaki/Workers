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
        print("Operation request tests passed")
    }
}
