import AppIntents
import CloudflareKit

struct GetWorkerErrorRateIntent: AppIntent {
    static let title: LocalizedStringResource = "Intents.ErrorRate.Title"
    @Parameter(title: "Intents.Worker.Type") var worker: WorkerEntity

    func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog {
        let points = try await IntentContext.client(accountId: worker.accountId).workerAnalytics(accountId: worker.accountId, range: .day, scriptName: worker.name)
        let requests = points.reduce(0) { $0 + $1.requests }
        let errors = points.reduce(0) { $0 + $1.errors }
        let percentage = requests > 0 ? Double(errors) / Double(requests) * 100 : 0
        let dialog: LocalizedStringResource = requests > 0
            ? .intentsErrorRateResult(worker.name, percentage.formatted(.number.precision(.fractionLength(2))))
            : .intentsErrorRateNoTraffic(worker.name)
        return .result(value: percentage, dialog: IntentDialog(dialog))
    }
}
