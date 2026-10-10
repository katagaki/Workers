import Foundation

public struct R2Bucket: Codable, Hashable, Identifiable, Sendable {
    public let name: String
    public let creationDate: Date?
    public let location: String?
    public let storageClass: String?

    public var id: String { name }
}
