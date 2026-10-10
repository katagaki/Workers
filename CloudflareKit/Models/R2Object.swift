import Foundation

public struct R2Object: Codable, Hashable, Identifiable, Sendable {
    public struct HTTPMetadata: Codable, Hashable, Sendable {
        public let contentType: String?
    }

    public let key: String
    public let size: Int?
    public let etag: String?
    public let lastModified: Date?
    public let httpMetadata: HTTPMetadata?
    public let storageClass: String?

    public var id: String { key }
}
