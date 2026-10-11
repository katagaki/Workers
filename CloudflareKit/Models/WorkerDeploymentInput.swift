import Foundation

public struct WorkerDeploymentInput: Encodable, Sendable {
    public struct Version: Encodable, Sendable {
        public let versionId: String
        public let percentage: Double

        public init(versionId: String, percentage: Double) {
            self.versionId = versionId
            self.percentage = percentage
        }
    }

    public let strategy = "percentage"
    public let versions: [Version]

    public init(versions: [Version]) {
        self.versions = versions
    }
}
