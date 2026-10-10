import Foundation

public struct WorkerTail: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let url: String
    public let expiresAt: Date?
}
