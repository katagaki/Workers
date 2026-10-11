import AppIntents
import CloudflareKit

struct RollbackWorkerIntent: AppIntent {
    static let title: LocalizedStringResource = "Intents.Rollback.Title"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @Parameter(title: "Intents.Worker.Type") var worker: WorkerEntity

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let client = try IntentContext.client(accountId: worker.accountId)
        let deployments = try await client.workerDeployments(accountId: worker.accountId, scriptName: worker.name).sorted { $0.createdOn > $1.createdOn }
        guard deployments.count > 1 else { throw IntentError.noPreviousDeployment }
        let previous = deployments[1]
        try await requestConfirmation(dialog: IntentDialog(.intentsRollbackConfirm(worker.name)))
        let current = try await client.workerDeployments(accountId: worker.accountId, scriptName: worker.name).sorted { $0.createdOn > $1.createdOn }
        guard current.first?.id == deployments.first?.id else { throw IntentError.deploymentChanged }
        let result = try await client.deployWorkerVersions(accountId: worker.accountId, scriptName: worker.name, versions: previous.versions.map { .init(versionId: $0.versionId, percentage: $0.percentage) })
        DiskCache.shared.remove(for: "worker-deployments-\(worker.accountId)-\(worker.name)")
        return .result(value: result.id, dialog: IntentDialog(.intentsRollbackResult(worker.name)))
    }
}
