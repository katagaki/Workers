import Foundation

public struct R2ObjectPage: Codable, Hashable, Sendable {
    public let objects: [R2Object]
    public let folders: [String]
    public let nextCursor: String?
}
