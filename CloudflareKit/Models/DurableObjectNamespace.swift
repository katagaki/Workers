import Foundation

public struct DurableObjectNamespace: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String?
    public let script: String?
    public let className: String?
    public let useSqlite: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case script
        case className = "class"
        case useSqlite
    }

    public var displayName: String {
        className ?? name ?? id
    }
}
