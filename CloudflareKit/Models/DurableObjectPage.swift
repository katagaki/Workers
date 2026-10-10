import Foundation

public struct DurableObjectPage: Codable, Hashable, Sendable {
    public let objects: [DurableObjectInstance]
    public let nextCursor: String?
}
