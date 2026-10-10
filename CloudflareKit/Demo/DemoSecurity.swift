import Foundation

final class DemoSecurity: @unchecked Sendable {
    static let shared = DemoSecurity()
    private let lock = NSLock()
    private var rulesByZone: [String: [[String: Any]]] = [:]

    func response(method: String, zoneId: String, parts: [String], body: [String: Any]?) -> [String: Any]? {
        lock.withLock {
            var rules = rulesByZone[zoneId] ?? initialRules
            if parts == ["rulesets", "phases", "http_request_firewall_custom", "entrypoint"], method == "GET" {
                return DemoRouter.envelope(ruleset(zoneId: zoneId, rules: rules))
            }
            if method == "POST", parts == ["rulesets"] {
                rules = body?["rules"] as? [[String: Any]] ?? []
                rules = rules.map { rule in
                    var rule = rule
                    rule["id"] = UUID().uuidString
                    return rule
                }
            } else if method == "POST", parts.count == 3, parts[2] == "rules" {
                var rule = body ?? [:]
                rule["id"] = UUID().uuidString
                rules.append(rule)
            } else if parts.count == 4, parts[2] == "rules",
                      let index = rules.firstIndex(where: { $0["id"] as? String == parts[3] }) {
                if method == "DELETE" {
                    rules.remove(at: index)
                } else if method == "PATCH" {
                    if let position = body?["position"] as? [String: String], let before = position["before"] {
                        let rule = rules.remove(at: index)
                        let destination = before.isEmpty ? 0 : rules.firstIndex(where: { $0["id"] as? String == before }) ?? rules.count
                        rules.insert(rule, at: destination)
                    } else {
                        rules[index].merge(body ?? [:]) { _, updated in updated }
                    }
                } else {
                    return nil
                }
            } else {
                return nil
            }
            rulesByZone[zoneId] = rules
            return DemoRouter.envelope(ruleset(zoneId: zoneId, rules: rules))
        }
    }

    private func ruleset(zoneId: String, rules: [[String: Any]]) -> [String: Any] {
        ["id": zoneId, "name": "Custom security rules", "kind": "zone", "phase": "http_request_firewall_custom", "rules": rules]
    }

    private var initialRules: [[String: Any]] {
        [
            ["id": "demo-security-admin", "description": "Challenge the admin area", "expression": "starts_with(http.request.uri.path, \"/admin\")", "action": "managed_challenge", "enabled": true],
            ["id": "demo-security-country", "description": "Block a country", "expression": "ip.src.country eq \"CN\"", "action": "block", "enabled": true],
            ["id": "demo-security-login", "description": "Challenge the login page", "expression": "http.request.uri.path eq \"/login\"", "action": "managed_challenge", "enabled": false]
        ]
    }
}
