import Foundation

public struct DNSRecordInput: Codable, Hashable, Sendable {
    public var type: String
    public var name: String
    public var content: String
    public var ttl: Int
    public var proxied: Bool?
    public var comment: String?
    public var priority: Int?

    public init(
        type: String,
        name: String,
        content: String,
        ttl: Int = 1,
        proxied: Bool? = nil,
        comment: String? = nil,
        priority: Int? = nil
    ) {
        self.type = type
        self.name = name
        self.content = content
        self.ttl = ttl
        self.proxied = proxied
        self.comment = comment
        self.priority = priority
    }

    public init(record: DNSRecord) {
        self.init(
            type: record.type,
            name: record.name,
            content: record.content,
            ttl: record.ttl,
            proxied: record.proxied,
            comment: record.comment,
            priority: record.priority
        )
    }

    public static let supportedTypes = ["A", "AAAA", "CNAME", "MX", "TXT", "NS", "SRV", "CAA", "PTR"]
    public static let proxiableTypes: Set<String> = ["A", "AAAA", "CNAME"]
}
