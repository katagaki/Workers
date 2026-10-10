import Foundation

public struct D1Database: Codable, Hashable, Identifiable, Sendable {
    public let uuid: String
    public let name: String
    public let version: String?
    public let createdAt: Date?
    public let fileSize: Int?
    public let numTables: Int?

    public var id: String { uuid }
}
