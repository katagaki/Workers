import Foundation

public struct WorkerBinding: Codable, Hashable, Sendable {
    public let name: String
    public let type: String
    public let className: String?
    public let scriptName: String?
    public let namespaceId: String?
    public let bucketName: String?
    public let databaseId: String?
    public let queueName: String?
    public let service: String?
    public let environment: String?
    public let dataset: String?
    public let text: String?
    public let id: String?

    public var bindingIdentifier: String { "\(type):\(name)" }
}
