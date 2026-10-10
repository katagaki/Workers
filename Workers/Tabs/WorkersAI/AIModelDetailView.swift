import CloudflareKit
import SwiftUI

struct AIModelDetailView: View {
    let client: CloudflareClient
    let accountId: String
    let modelId: String
    @State private var range: AnalyticsRange = .day
    @State private var analytics: CachedResource<[AIAnalyticsPoint]>

    init(client: CloudflareClient, accountId: String, modelId: String) {
        self.client = client
        self.accountId = accountId
        self.modelId = modelId
        _analytics = State(initialValue: CachedResource(key: "ai-model-\(accountId)-\(modelId)-day"))
    }

    private var points: [AIAnalyticsPoint] { analytics.value ?? [] }

    var body: some View {
        List {
            Section {
                AnalyticsRangePicker(range: $range)
                AnalyticsSectionStatus(resource: analytics)
                if analytics.value != nil {
                    let requests = points.reduce(0) { $0 + $1.requests }
                    let errors = points.reduce(0) { $0 + $1.errors }
                    StatGrid(stats: [
                        Stat(title: .statsRequests, value: requests.compactFormatted),
                        Stat(title: .statsErrors, value: errors.compactFormatted, tint: errors > 0 ? .red : .primary),
                        Stat(title: .workersAIUsageTitle, value: number(points.reduce(0) { $0 + $1.neurons })),
                        Stat(title: .workersAIAverageInference, value: (requests > 0 ? points.reduce(0) { $0 + $1.inferenceTimeMilliseconds } / Double(requests) : 0).millisecondsFormatted),
                        Stat(title: .workersAIInputTokens, value: number(points.reduce(0) { $0 + $1.inputTokens })),
                        Stat(title: .workersAIOutputTokens, value: number(points.reduce(0) { $0 + $1.outputTokens }))
                    ])
                    SeriesChart(title: .statsRequests, points: chartPoints { Double($0.requests) }, range: range, tint: .orange)
                    SeriesChart(title: .workersAIUsageTitle, points: chartPoints { $0.neurons }, range: range, tint: .blue)
                }
                if let error = analytics.error, analytics.value != nil {
                    Label(error.localizedDescription, systemImage: "exclamationmark.triangle").foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(modelId.split(separator: "/").last.map(String.init) ?? modelId)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: range) {
            analytics = CachedResource(key: "ai-model-\(accountId)-\(modelId)-\(range.rawValue)")
            await reload()
        }
        .refreshable { await reload() }
    }

    private func number(_ value: Double) -> String {
        value.formatted(.number.notation(.compactName))
    }

    private func chartPoints(value: (AIAnalyticsPoint) -> Double) -> [ChartPoint] {
        Dictionary(grouping: points, by: \.date).map { date, points in
            ChartPoint(date: date, series: modelId, value: points.reduce(0) { $0 + value($1) })
        }.sorted { $0.date < $1.date }
    }

    private func reload() async {
        await analytics.refresh {
            try await client.aiAnalytics(accountId: accountId, range: range, modelId: modelId)
        }
    }
}
