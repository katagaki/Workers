import CloudflareKit
import SwiftUI

struct WorkerAnalyticsSummary: View {
    let client: CloudflareClient
    let accountId: String
    let scriptName: String
    let range: AnalyticsRange

    @State private var analytics: CachedResource<[WorkerAnalyticsPoint]>

    init(client: CloudflareClient, accountId: String, scriptName: String, range: AnalyticsRange) {
        self.client = client
        self.accountId = accountId
        self.scriptName = scriptName
        self.range = range
        _analytics = State(initialValue: CachedResource(key: "worker-analytics-\(accountId)-\(scriptName)-\(range.rawValue)"))
    }

    private var points: [WorkerAnalyticsPoint] {
        analytics.value ?? []
    }

    private var totalRequests: Int {
        points.reduce(0) { $0 + $1.requests }
    }

    private var totalErrors: Int {
        points.reduce(0) { $0 + $1.errors }
    }

    private var medianCPUTime: Double {
        guard totalRequests > 0 else { return 0 }
        let weighted = points.reduce(0) { $0 + $1.cpuTimeP50 * Double($1.requests) }
        return weighted / Double(totalRequests)
    }

    var body: some View {
        Group {
            if analytics.value == nil, let error = analytics.error {
                Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if analytics.value == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                StatGrid(stats: [
                    Stat(title: .statsRequests, value: totalRequests.compactFormatted),
                    Stat(
                        title: .statsErrors,
                        value: totalErrors.compactFormatted,
                        tint: totalErrors > 0 ? .red : .primary
                    ),
                    Stat(
                        title: .statsErrorRate,
                        value: (totalRequests > 0 ? Double(totalErrors) / Double(totalRequests) : 0).percentFormatted
                    ),
                    Stat(title: .statsMedianCPUTime, value: medianCPUTime.millisecondsFromMicroseconds)
                ])
                SeriesChart(
                    title: .statsRequests,
                    points: points.map {
                        ChartPoint(date: $0.date, series: String(localized: .statsRequests), value: Double($0.requests))
                    },
                    range: range,
                    tint: .orange
                )
                if totalErrors > 0 {
                    SeriesChart(
                        title: .statsErrors,
                        points: points.map {
                            ChartPoint(date: $0.date, series: String(localized: .statsErrors), value: Double($0.errors))
                        },
                        range: range,
                        style: .bar,
                        tint: .red
                    )
                }
            }
        }
        .task {
            await analytics.refresh {
                try await client.workerAnalytics(accountId: accountId, range: range, scriptName: scriptName)
            }
        }
    }
}
