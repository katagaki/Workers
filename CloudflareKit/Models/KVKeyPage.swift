import Foundation

public struct KVKeyPage: Codable, Hashable, Sendable {
    public let keys: [KVKey]
    public let nextCursor: String?
}
