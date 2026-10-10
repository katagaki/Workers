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
struct WorkersAITests {
    static func main() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureProtocol.self]
        let client = CloudflareClient(token: "fixture-only", session: URLSession(configuration: configuration))
        let fixtures = RequestFixtures.shared
        let response = #"{"data":{"viewer":{"accounts":[{"aiInferenceAdaptiveGroups":[{"count":12,"sum":{"totalNeurons":15.5,"totalInputTokens":120,"totalOutputTokens":80,"totalInferenceTimeMs":2400},"dimensions":{"datetimeHour":"2026-10-10T01:00:00Z","modelId":"model","errorCode":0}},{"count":2,"sum":{"totalNeurons":0,"totalInputTokens":0,"totalOutputTokens":0,"totalInferenceTimeMs":0},"dimensions":{"datetimeHour":"2026-10-10T01:00:00Z","modelId":"model","errorCode":3036}}]}]}}}"#
        fixtures.enqueue(json: response)
        let start = Date(timeIntervalSince1970: 1_791_590_400)
        let points = try await client.aiAnalytics(accountId: "account", range: .day, modelId: "model\"quoted", since: start)
        precondition(points.count == 2)
        precondition(points.reduce(0) { $0 + $1.requests } == 14)
        precondition(points.reduce(0) { $0 + $1.errors } == 2)
        precondition(points.reduce(0) { $0 + $1.neurons } == 15.5)
        precondition(points.first?.inferenceTimeMilliseconds == 2400)
        let body = try JSONSerialization.jsonObject(with: fixtures.lastRequest.httpBody!) as! [String: String]
        let query = body["query"]!
        precondition(query.contains("datetimeHour"))
        precondition(query.contains(start.formatted(.iso8601)))
        precondition(query.contains(#"modelId: "model\"quoted""#))
        precondition(!query.contains("aiGateway"))

        fixtures.enqueue(json: #"{"data":{"viewer":{"accounts":[{"aiInferenceAdaptiveGroups":[{"count":3,"sum":{"totalNeurons":7,"totalInputTokens":0,"totalOutputTokens":0,"totalInferenceTimeMs":100},"dimensions":{"date":"2026-10-01","modelId":"image-model","errorCode":0}}]}]}}}"#)
        let monthly = try await client.aiAnalytics(accountId: "account", range: .month)
        precondition(monthly.first?.requests == 3)
        precondition(monthly.first?.inputTokens == 0)

        fixtures.enqueue(json: #"{"data":{"viewer":{"accounts":[{"aiInferenceAdaptiveGroups":[]}]}}}"#)
        let empty = try await client.aiAnalytics(accountId: "account", range: .week)
        precondition(empty.isEmpty)

        fixtures.enqueue(json: #"{"errors":[{"message":"Missing Account Analytics permission"}]}"#)
        do {
            _ = try await client.aiAnalytics(accountId: "account", range: .day)
            preconditionFailure("Permission errors must remain visible")
        } catch CloudflareError.graphQL(let messages) {
            precondition(messages.first == "Missing Account Analytics permission")
        }
        print("Workers AI request tests passed")
    }
}
