import Foundation

public struct ZoneAnalyticsPoint: Codable, Hashable, Identifiable, Sendable {
    public let date: Date
    public let zoneId: String
    public let requests: Int
    public let cachedRequests: Int
    public let bytes: Int
    public let cachedBytes: Int
    public let threats: Int
    public let pageViews: Int
    public let uniqueVisitors: Int

    public var id: String { "\(zoneId)-\(date.timeIntervalSince1970)" }
}
