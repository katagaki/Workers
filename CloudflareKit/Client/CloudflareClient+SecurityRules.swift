import Foundation

public extension CloudflareClient {
    func securityRuleset(zoneId: String) async throws -> SecurityRuleset {
        do {
            return try await securityResult(path: "zones/\(zoneId)/rulesets/phases/http_request_firewall_custom/entrypoint")
        } catch CloudflareError.http(statusCode: 404) {
            return SecurityRuleset()
        }
    }

    func createSecurityRule(zoneId: String, rulesetId: String?, input: SecurityRuleInput) async throws -> SecurityRuleset {
        if let rulesetId {
            return try await securityResult(.post, path: "zones/\(zoneId)/rulesets/\(rulesetId)/rules", body: try encode(input))
        }
        struct EntryPoint: Encodable {
            let name = "Custom security rules"
            let kind = "zone"
            let phase = "http_request_firewall_custom"
            let rules: [SecurityRuleInput]
        }
        return try await securityResult(
            .post, path: "zones/\(zoneId)/rulesets", body: try encode(EntryPoint(rules: [input]))
        )
    }

    func updateSecurityRule(zoneId: String, rulesetId: String, ruleId: String, input: SecurityRuleInput) async throws -> SecurityRuleset {
        try await securityResult(.patch, path: "zones/\(zoneId)/rulesets/\(rulesetId)/rules/\(ruleId)", body: try encode(input))
    }

    func setSecurityRuleEnabled(zoneId: String, rulesetId: String, ruleId: String, enabled: Bool) async throws -> SecurityRuleset {
        let current = try await securityRuleset(zoneId: zoneId)
        guard current.id == rulesetId, let rule = current.rules.first(where: { $0.id == ruleId }) else {
            throw CloudflareError.http(statusCode: 404)
        }
        var input = SecurityRuleInput(rule: rule)
        input.enabled = enabled
        return try await updateSecurityRule(zoneId: zoneId, rulesetId: rulesetId, ruleId: ruleId, input: input)
    }

    func moveSecurityRule(zoneId: String, rulesetId: String, ruleId: String, beforeRuleId: String) async throws -> SecurityRuleset {
        try await securityResult(
            .patch, path: "zones/\(zoneId)/rulesets/\(rulesetId)/rules/\(ruleId)",
            body: try encode(["position": ["before": beforeRuleId]])
        )
    }

    func deleteSecurityRule(zoneId: String, rulesetId: String, ruleId: String) async throws -> SecurityRuleset {
        try await securityResult(.delete, path: "zones/\(zoneId)/rulesets/\(rulesetId)/rules/\(ruleId)")
    }
}

private extension CloudflareClient {
    func securityResult(_ method: HTTPMethod = .get, path: String, body: Data? = nil) async throws -> SecurityRuleset {
        let request = try makeRequest(method, path: path, body: body)
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw CloudflareError.invalidResponse }
        if [401, 403, 404].contains(response.statusCode) {
            throw CloudflareError.http(statusCode: response.statusCode)
        }
        let envelope = try CloudflareJSON.makeDecoder().decode(APIEnvelope<SecurityRuleset>.self, from: data)
        if envelope.success != true, let errors = envelope.errors, !errors.isEmpty {
            throw CloudflareError.api(messages: errors.map(\.message))
        }
        guard (200..<300).contains(response.statusCode) else { throw CloudflareError.http(statusCode: response.statusCode) }
        guard envelope.success == true, let result = envelope.result else { throw CloudflareError.invalidResponse }
        return result
    }
}
