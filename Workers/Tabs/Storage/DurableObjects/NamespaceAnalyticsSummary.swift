import CloudflareKit
import SwiftUI

struct NamespaceAnalyticsSummary: View {
    let client: CloudflareClient
    let accountId: String
    let namespaceId: String
    let range: AnalyticsRange

    @State private var analytics: CachedResource<[DurableObjectAnalyticsPoint]>

    init(client: CloudflareClient, accountId: String, namespaceId: String, range: AnalyticsRange) {
        self.client = client
        self.accountId = accountId
        self.namespaceId = namespaceId
        self.range = range
        _analytics = State(initialValue: CachedResource(key: "do-analytics-\(accountId)-\(namespaceId)-\(range.rawValue)"))
    }

    var body: some View {
        Group {
            if analytics.value == nil, let error = analytics.error {
                Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let points = analytics.value {
                StatGrid(stats: [
                    Stat(title: .statsRequests, value: points.reduce(0) { $0 + $1.requests }.compactFormatted)
                ])
                SeriesChart(
                    title: .durableObjectsRequestsOverTime,
                    points: points.map {
                        ChartPoint(date: $0.date, series: String(localized: .statsRequests), value: Double($0.requests))
                    },
                    range: range,
                    tint: .orange
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 160)
            }
        }
        .task {
            await analytics.refresh {
                try await client.durableObjectAnalytics(accountId: accountId, range: range, namespaceId: namespaceId)
            }
        }
    }
}
