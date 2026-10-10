import Foundation

public struct WorkerDeployment: Codable, Hashable, Identifiable, Sendable {
    public struct VersionAllocation: Codable, Hashable, Sendable {
        public let versionId: String
        public let percentage: Double
    }

    public let id: String
    public let createdOn: Date
    public let source: String?
    public let strategy: String?
    public let authorEmail: String?
    public let annotations: WorkerAnnotations?
    public let versions: [VersionAllocation]
}
