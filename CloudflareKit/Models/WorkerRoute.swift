import Foundation

public struct WorkerRoute: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let pattern: String
    public let script: String?
}
