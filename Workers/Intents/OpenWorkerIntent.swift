import AppIntents
import CloudflareKit

struct OpenWorkerIntent: OpenIntent {
    static let title: LocalizedStringResource = "Intents.OpenWorker.Title"
    static let supportedModes: IntentModes = .foreground

    @Parameter(title: "Intents.Worker.Type")
    var target: WorkerEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        let client = try IntentContext.client()
        guard let script = try await client.workerScripts(accountId: target.accountId)
            .first(where: { $0.name == target.name }) else {
            throw IntentError.workerNotFound
        }
        AppNavigator.shared.open(.worker(script), accountId: target.accountId)
        return .result()
    }
}
