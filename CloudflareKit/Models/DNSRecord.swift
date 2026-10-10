import Foundation

public struct DNSRecord: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let type: String
    public let name: String
    public let content: String
    public let proxied: Bool?
    public let proxiable: Bool?
    public let ttl: Int
    public let comment: String?
    public let priority: Int?
    public let createdOn: Date?
    public let modifiedOn: Date?
}
