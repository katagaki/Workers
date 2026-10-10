import Foundation

public struct WorkerScript: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let createdOn: Date?
    public let modifiedOn: Date?
    public let usageModel: String?
    public let handlers: [String]?
    public let compatibilityDate: String?
    public let compatibilityFlags: [String]?
    public let lastDeployedFrom: String?
    public let hasModules: Bool?
    public let logpush: Bool?

    public var name: String { id }
}
