import Foundation

public struct ZoneOutcomePoint: Codable, Hashable, Identifiable, Sendable {
    public let date: Date
    public let mitigated: Int
    public let servedByCloudflare: Int
    public let servedByOrigin: Int

    public var id: Date { date }
}
