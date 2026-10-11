import CloudflareKit
import Foundation

struct WorkerDeploymentAction: Identifiable {
    let id: String
    let versions: [WorkerDeploymentInput.Version]
    let isRollback: Bool

    init(deployment: WorkerDeployment) {
        id = deployment.id
        versions = deployment.versions.map { .init(versionId: $0.versionId, percentage: $0.percentage) }
        isRollback = true
    }

    init(version: WorkerVersion) {
        id = version.id
        versions = [.init(versionId: version.id, percentage: 100)]
        isRollback = false
    }
}
