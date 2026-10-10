import Foundation

public struct WorkerCustomDomain: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let hostname: String
    public let service: String
    public let environment: String?
    public let zoneId: String?
    public let zoneName: String?
}
