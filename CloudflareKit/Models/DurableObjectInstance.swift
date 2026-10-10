import Foundation

public struct DurableObjectInstance: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let hasStoredData: Bool?
}
