import Foundation

public struct KVKeyPage: Codable, Hashable, Sendable {
    public let keys: [KVKey]
    public let nextCursor: String?

    public init(keys: [KVKey], nextCursor: String?) {
        self.keys = keys
        self.nextCursor = nextCursor
    }
}
