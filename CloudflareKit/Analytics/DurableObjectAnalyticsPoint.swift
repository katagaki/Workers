import Foundation

public struct DurableObjectAnalyticsPoint: Codable, Hashable, Identifiable, Sendable {
    public let date: Date
    public let namespaceId: String
    public let requests: Int

    public var id: String { "\(namespaceId)-\(date.timeIntervalSince1970)" }
}
