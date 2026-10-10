import CloudflareKit
import SwiftUI

struct WorkersAnalyticsSection: View {
    let client: CloudflareClient
    let accountId: String
    let range: AnalyticsRange

    @State private var analytics: CachedResource<[WorkerAnalyticsPoint]>

    init(client: CloudflareClient, accountId: String, range: AnalyticsRange) {
        self.client = client
        self.accountId = accountId
        self.range = range
        _analytics = State(initialValue: CachedResource(key: "workers-analytics-\(accountId)-\(range.rawValue)"))
    }

    private var points: [WorkerAnalyticsPoint] {
        analytics.value ?? []
    }

    private var totals: [(name: String, requests: Int, errors: Int)] {
        Dictionary(grouping: points, by: \.scriptName)
            .map { name, items in
                (name, items.reduce(0) { $0 + $1.requests }, items.reduce(0) { $0 + $1.errors })
            }
            .sorted { $0.requests > $1.requests }
    }

    private var errorPoints: [ChartPoint] {
        Dictionary(grouping: points, by: \.date)
            .map { date, items in
                ChartPoint(date: date, series: String(localized: .statsErrors), value: Double(items.reduce(0) { $0 + $1.errors }))
            }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        Section {
            AnalyticsSectionStatus(resource: analytics)
            if analytics.value != nil {
                let requests = points.reduce(0) { $0 + $1.requests }
                let errors = points.reduce(0) { $0 + $1.errors }
                StatGrid(stats: [
                    Stat(title: .statsRequests, value: requests.compactFormatted),
                    Stat(title: .statsErrors, value: errors.compactFormatted, tint: errors > 0 ? .red : .primary),
                    Stat(
                        title: .statsErrorRate,
                        value: (requests > 0 ? Double(errors) / Double(requests) : 0).percentFormatted
                    ),
                    Stat(title: .statsSubrequests, value: points.reduce(0) { $0 + $1.subrequests }.compactFormatted)
                ])
                SeriesChart(
                    title: .analyticsRequestsByWorker,
                    points: points.map {
                        ChartPoint(date: $0.date, series: $0.scriptName, value: Double($0.requests))
                    },
                    range: range
                )
                if errors > 0 {
                    SeriesChart(title: .statsErrors, points: errorPoints, range: range, style: .bar, tint: .red)
                }
                ForEach(totals.prefix(10), id: \.name) { total in
                    AnalyticsBreakdownRow(
                        title: total.name,
                        value: total.requests.compactFormatted,
                        detail: total.errors > 0 ? String(localized: .statsErrorCount(total.errors.compactFormatted)) : nil,
                        detailTint: .red
                    )
                }
            }
        } header: {
            Text(.tabsWorkers)
        }
        .task {
            await analytics.refresh {
                try await client.workerAnalytics(accountId: accountId, range: range)
            }
        }
    }
}
