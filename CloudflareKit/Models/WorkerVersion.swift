import Foundation

public struct WorkerVersion: Codable, Hashable, Identifiable, Sendable {
    public struct Metadata: Codable, Hashable, Sendable {
        public let createdOn: Date?
        public let modifiedOn: Date?
        public let authorEmail: String?
        public let source: String?
        public let hasPreview: Bool?
    }

    public let id: String
    public let number: Int?
    public let metadata: Metadata?
    public let annotations: WorkerAnnotations?
}
