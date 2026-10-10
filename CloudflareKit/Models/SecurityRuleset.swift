import Foundation

public struct SecurityRuleset: Codable, Sendable {
    public let id: String?
    public var rules: [SecurityRule]

    public init(id: String? = nil, rules: [SecurityRule] = []) {
        self.id = id
        self.rules = rules
    }

    private enum CodingKeys: String, CodingKey {
        case id, rules
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        rules = try container.decodeIfPresent([SecurityRule].self, forKey: .rules) ?? []
    }
}

public struct SecurityRule: Codable, Identifiable, Sendable {
    public let id: String
    public let description: String?
    public let expression: String
    public let action: String
    public let enabled: Bool?
    public let actionParameters: JSONValue?
    public let logging: JSONValue?
    public let ref: String?
    public let ratelimit: JSONValue?
    public let exposedCredentialCheck: JSONValue?
    public let version: String?
}

public struct SecurityRuleInput: Encodable, Sendable {
    public var description: String
    public var expression: String
    public var action: String
    public var enabled: Bool
    public var actionParameters: JSONValue?
    public var logging: JSONValue?
    public var ref: String?
    public var ratelimit: JSONValue?
    public var exposedCredentialCheck: JSONValue?

    public init() {
        description = ""
        expression = ""
        action = "managed_challenge"
        enabled = true
    }

    public init(rule: SecurityRule) {
        description = rule.description ?? ""
        expression = rule.expression
        action = rule.action
        enabled = rule.enabled ?? true
        actionParameters = rule.actionParameters
        logging = rule.logging
        ref = rule.ref
        ratelimit = rule.ratelimit
        exposedCredentialCheck = rule.exposedCredentialCheck
    }
}
