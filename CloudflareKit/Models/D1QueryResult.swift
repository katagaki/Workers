import Foundation

public struct D1QueryResult: Codable, Hashable, Sendable {
    public struct Rows: Codable, Hashable, Sendable {
        public let columns: [String]?
        public let rows: [[JSONValue]]?
    }

    public struct Meta: Codable, Hashable, Sendable {
        public let duration: Double?
        public let rowsRead: Int?
        public let rowsWritten: Int?
        public let changes: Int?
    }

    public let results: Rows?
    public let meta: Meta?
    public let success: Bool?

    public var columns: [String] { results?.columns ?? [] }
    public var rows: [[JSONValue]] { results?.rows ?? [] }
}
