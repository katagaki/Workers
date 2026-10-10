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
            requests.append(request)
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
struct RequestTests {
    static let envelope = #"{"success":true,"errors":[],"result":{"id":"ruleset","rules":[{"id":"rule","action":"skip","expression":"true","description":"Advanced","enabled":true,"ref":"keep-ref","version":"2","action_parameters":{"ruleset":"current","phases":["http_ratelimit"],"response":{"content_type":"application/json","status_code":403}},"logging":{"enabled":true},"ratelimit":{"requests_per_period":5},"exposed_credential_check":{"username_expression":"http.request.uri.path"}}]}}"#

    static func require(_ condition: Bool, _ message: String) {
        precondition(condition, message)
    }

    static func body(of request: URLRequest) throws -> [String: Any] {
        var data = request.httpBody ?? Data()
        if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 { break }
                data.append(buffer, count: count)
            }
        }
        return try JSONSerialization.jsonObject(with: data) as! [String: Any]
    }

    static func main() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureProtocol.self]
        let client = CloudflareClient(token: "fixture-only", session: URLSession(configuration: configuration))
        let fixtures = RequestFixtures.shared

        fixtures.enqueue(status: 404, json: #"{"success":false,"errors":[{"message":"Missing ruleset"}]}"#)
        let empty = try await client.securityRuleset(zoneId: "zone")
        require(empty.id == nil && empty.rules.isEmpty, "404 must represent an absent entry point")

        fixtures.enqueue(json: #"{"success":true,"result":{"id":"empty-ruleset"}}"#)
        let existingEmpty = try await client.securityRuleset(zoneId: "zone")
        require(existingEmpty.id == "empty-ruleset" && existingEmpty.rules.isEmpty, "An empty ruleset can omit its rules array")

        fixtures.enqueue(status: 403, json: #"{"success":false,"errors":[{"message":"Forbidden"}]}"#)
        do {
            _ = try await client.securityRuleset(zoneId: "zone")
            preconditionFailure("403 must not become an empty ruleset")
        } catch CloudflareError.http(statusCode: 403) {}

        fixtures.enqueue(json: envelope)
        let current = try await client.securityRuleset(zoneId: "zone")
        let input = SecurityRuleInput(rule: current.rules[0])
        fixtures.enqueue(json: envelope)
        _ = try await client.updateSecurityRule(zoneId: "zone", rulesetId: "ruleset", ruleId: "rule", input: input)
        let edit = try body(of: fixtures.lastRequest)
        require(edit["ref"] as? String == "keep-ref", "Reference must survive editing")
        let parameters = edit["action_parameters"] as! [String: Any]
        let response = parameters["response"] as! [String: Any]
        require(response["content_type"] as? String == "application/json", "Nested API keys must survive coding")
        require(edit["logging"] != nil && edit["ratelimit"] != nil && edit["exposed_credential_check"] != nil, "Advanced settings must survive editing")
        require(edit["id"] == nil && edit["version"] == nil, "Read-only metadata must not be written")

        fixtures.enqueue(json: envelope)
        fixtures.enqueue(json: envelope)
        _ = try await client.setSecurityRuleEnabled(zoneId: "zone", rulesetId: "ruleset", ruleId: "rule", enabled: false)
        let toggle = try body(of: fixtures.lastRequest)
        require(toggle["enabled"] as? Bool == false && toggle["action_parameters"] != nil && toggle["expression"] as? String == "true", "Toggle must preserve the full definition")

        fixtures.enqueue(json: envelope)
        _ = try await client.moveSecurityRule(zoneId: "zone", rulesetId: "ruleset", ruleId: "rule", beforeRuleId: "")
        let move = try body(of: fixtures.lastRequest)
        require(move.count == 1 && (move["position"] as? [String: String])?["before"] == "", "Reorder must only change position")

        fixtures.enqueue(json: envelope)
        _ = try await client.createSecurityRule(zoneId: "zone", rulesetId: nil, input: input)
        let create = try body(of: fixtures.lastRequest)
        require(fixtures.lastRequest.httpMethod == "POST" && fixtures.lastRequest.url!.path.hasSuffix("/zones/zone/rulesets"), "First rule must create a ruleset without replacing an existing entry point")
        require(create["phase"] as? String == "http_request_firewall_custom", "Only the custom WAF phase is supported")

        fixtures.enqueue(json: envelope)
        _ = try await client.createSecurityRule(zoneId: "zone", rulesetId: "ruleset", input: input)
        require(fixtures.lastRequest.url!.path.hasSuffix("/rulesets/ruleset/rules"), "Subsequent rules must append")

        fixtures.enqueue(json: envelope)
        _ = try await client.deleteSecurityRule(zoneId: "zone", rulesetId: "ruleset", ruleId: "rule")
        require(fixtures.lastRequest.httpMethod == "DELETE", "Delete must use the rule endpoint")

        fixtures.enqueue(status: 400, json: #"{"success":false,"errors":[{"message":"Invalid expression"}]}"#)
        do {
            _ = try await client.updateSecurityRule(zoneId: "zone", rulesetId: "ruleset", ruleId: "rule", input: input)
            preconditionFailure("API validation failures must propagate")
        } catch CloudflareError.api(let messages) {
            require(messages == ["Invalid expression"], "Validation details must be preserved")
        }
        print("Security rules request tests passed")
    }
}
