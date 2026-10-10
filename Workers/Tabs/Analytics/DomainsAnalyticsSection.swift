import CloudflareKit
import SwiftUI

struct DomainsAnalyticsSection: View {
    let client: CloudflareClient
    let accountId: String
    let range: AnalyticsRange

    @State private var zones: CachedResource<[Zone]>
    @State private var analytics: CachedResource<[ZoneAnalyticsPoint]>

    private static let zonesPerQuery = 10

    init(client: CloudflareClient, accountId: String, range: AnalyticsRange) {
        self.client = client
        self.accountId = accountId
        self.range = range
        _zones = State(initialValue: CachedResource(key: "zones-\(accountId)"))
        _analytics = State(initialValue: CachedResource(key: "zones-analytics-\(accountId)-\(range.rawValue)"))
    }

    private var zoneNames: [String: String] {
        Dictionary((zones.value ?? []).map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
    }

    private var points: [ZoneAnalyticsPoint] {
        analytics.value ?? []
    }

    private var totals: [(name: String, requests: Int, bytes: Int)] {
        let names = zoneNames
        return Dictionary(grouping: points, by: \.zoneId)
            .map { zoneId, items in
                (names[zoneId] ?? zoneId, items.reduce(0) { $0 + $1.requests }, items.reduce(0) { $0 + $1.bytes })
            }
            .sorted { $0.requests > $1.requests }
    }

    var body: some View {
        Section {
            AnalyticsSectionStatus(resource: analytics)
            if analytics.value != nil {
                let requests = points.reduce(0) { $0 + $1.requests }
                let cached = points.reduce(0) { $0 + $1.cachedRequests }
                StatGrid(stats: [
                    Stat(title: .statsRequests, value: requests.compactFormatted),
                    Stat(title: .statsBandwidth, value: points.reduce(0) { $0 + $1.bytes }.byteFormatted),
                    Stat(title: .statsCached, value: (requests > 0 ? Double(cached) / Double(requests) : 0).percentFormatted),
                    Stat(title: .statsThreatsBlocked, value: points.reduce(0) { $0 + $1.threats }.compactFormatted)
                ])
                SeriesChart(
                    title: .analyticsRequestsByDomain,
                    points: points.map {
                        ChartPoint(date: $0.date, series: zoneNames[$0.zoneId] ?? $0.zoneId, value: Double($0.requests))
                    },
                    range: range
                )
                ForEach(totals.prefix(10), id: \.name) { total in
                    AnalyticsBreakdownRow(
                        title: total.name,
                        value: total.requests.compactFormatted,
                        detail: total.bytes.byteFormatted
                    )
                }
            }
        } header: {
            Text(.tabsDomains)
        }
        .task { await reload() }
    }

    private func reload() async {
        let client = client
        await zones.refresh {
            try await client.zones(accountId: accountId)
        }
        let zoneIds = (zones.value ?? []).filter { $0.status == "active" }.map(\.id)
        let chunks = stride(from: 0, to: zoneIds.count, by: Self.zonesPerQuery).map {
            Array(zoneIds[$0..<min($0 + Self.zonesPerQuery, zoneIds.count)])
        }
        let range = range
        await analytics.refresh {
            try await withThrowingTaskGroup(of: [ZoneAnalyticsPoint].self) { group in
                for chunk in chunks {
                    group.addTask {
                        try await client.zoneAnalytics(zoneIds: chunk, range: range)
                    }
                }
                var all: [ZoneAnalyticsPoint] = []
                for try await chunkPoints in group {
                    all += chunkPoints
                }
                return all
            }
        }
    }
}
