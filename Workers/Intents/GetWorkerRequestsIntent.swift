import AppIntents
import CloudflareKit

struct GetWorkerRequestsIntent: AppIntent {
    static let title: LocalizedStringResource = "Intents.WorkerRequests.Title"
    static let description = IntentDescription("Intents.WorkerRequests.Description")

    @Parameter(title: "Intents.Worker.Type")
    var worker: WorkerEntity

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        let points = try await IntentContext.client().workerAnalytics(
            accountId: worker.accountId,
            range: .day,
            scriptName: worker.name
        )
        let requests = points.reduce(0) { $0 + $1.requests }
        let errors = points.reduce(0) { $0 + $1.errors }
        return .result(
            value: requests,
            dialog: IntentDialog(.intentsWorkerRequestsResult(worker.name, requests.compactFormatted, errors.compactFormatted))
        )
    }
}
