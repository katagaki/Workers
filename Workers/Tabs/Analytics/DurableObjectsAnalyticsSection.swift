import CloudflareKit
import SwiftUI

struct DurableObjectsAnalyticsSection: View {
    let client: CloudflareClient
    let accountId: String
    let range: AnalyticsRange

    @State private var namespaces: CachedResource<[DurableObjectNamespace]>
    @State private var analytics: CachedResource<[DurableObjectAnalyticsPoint]>

    init(client: CloudflareClient, accountId: String, range: AnalyticsRange) {
        self.client = client
        self.accountId = accountId
        self.range = range
        _namespaces = State(initialValue: CachedResource(key: "do-namespaces-\(accountId)"))
        _analytics = State(initialValue: CachedResource(key: "do-analytics-\(accountId)-\(range.rawValue)"))
    }

    private var namespaceNames: [String: String] {
        Dictionary(
            (namespaces.value ?? []).map { ($0.id, $0.displayName) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    private var points: [DurableObjectAnalyticsPoint] {
        analytics.value ?? []
    }

    private var totals: [(name: String, requests: Int)] {
        let names = namespaceNames
        return Dictionary(grouping: points, by: \.namespaceId)
            .map { namespaceId, items in
                (names[namespaceId] ?? namespaceId, items.reduce(0) { $0 + $1.requests })
            }
            .sorted { $0.requests > $1.requests }
    }

    var body: some View {
        Section {
            AnalyticsSectionStatus(resource: analytics)
            if analytics.value != nil {
                StatGrid(stats: [
                    Stat(title: .statsRequests, value: points.reduce(0) { $0 + $1.requests }.compactFormatted),
                    Stat(title: .statsActiveNamespaces, value: Set(points.map(\.namespaceId)).count.formatted())
                ])
                SeriesChart(
                    title: .analyticsRequestsByNamespace,
                    points: points.map {
                        ChartPoint(
                            date: $0.date,
                            series: namespaceNames[$0.namespaceId] ?? $0.namespaceId,
                            value: Double($0.requests)
                        )
                    },
                    range: range
                )
                ForEach(totals.prefix(10), id: \.name) { total in
                    AnalyticsBreakdownRow(title: total.name, value: total.requests.compactFormatted)
                }
            }
        } header: {
            Text(.tabsDurableObjects)
        }
        .task {
            async let namespacesLoad: Void = namespaces.refresh {
                try await client.durableObjectNamespaces(accountId: accountId)
            }
            async let analyticsLoad: Void = analytics.refresh {
                try await client.durableObjectAnalytics(accountId: accountId, range: range)
            }
            _ = await (namespacesLoad, analyticsLoad)
        }
    }
}
