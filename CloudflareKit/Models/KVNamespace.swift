import Foundation

public struct KVNamespace: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
}
