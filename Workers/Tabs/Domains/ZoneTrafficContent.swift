import CloudflareKit
import SwiftUI

struct ZoneTrafficContent: View {
    let points: [ZoneAnalyticsPoint]
    let outcomes: [ZoneOutcomePoint]?
    let range: AnalyticsRange

    private var requests: Int { points.reduce(0) { $0 + $1.requests } }
    private var cachedRequests: Int { points.reduce(0) { $0 + $1.cachedRequests } }
    private var bytes: Int { points.reduce(0) { $0 + $1.bytes } }
    private var threats: Int { points.reduce(0) { $0 + $1.threats } }
    private var uniqueVisitors: Int { points.reduce(0) { $0 + $1.uniqueVisitors } }

    private var bytesByDate: [Date: Int] {
        points.reduce(into: [:]) { result, point in
            result[point.date, default: 0] += point.bytes
        }
    }

    private static let outcomeSeries: [SeriesChart.Series] = [
        SeriesChart.Series(name: String(localized: .domainsTrafficMitigated), color: .blue),
        SeriesChart.Series(name: String(localized: .domainsTrafficServedByCloudflare), color: .orange),
        SeriesChart.Series(name: String(localized: .domainsTrafficServedByOrigin), color: .pink)
    ]

    var body: some View {
        StatGrid(stats: [
            Stat(title: .statsRequests, value: requests.compactFormatted),
            Stat(title: .statsUniqueVisitors, value: uniqueVisitors.compactFormatted),
            Stat(title: .statsBandwidth, value: bytes.byteFormatted),
            Stat(
                title: .statsCached,
                value: (requests > 0 ? Double(cachedRequests) / Double(requests) : 0).percentFormatted
            ),
            Stat(title: .statsThreatsBlocked, value: threats.compactFormatted)
        ])
        if let outcomes {
            SeriesChart(
                title: .domainsRequestsByOutcome,
                points: outcomes.flatMap { outcome in
                    zip(Self.outcomeSeries, [outcome.mitigated, outcome.servedByCloudflare, outcome.servedByOrigin]).map { series, value in
                        ChartPoint(date: outcome.date, series: series.name, value: Double(value))
                    }
                },
                range: range,
                series: Self.outcomeSeries,
                showsLegendTotals: true
            )
        }
        SeriesChart(
            title: .statsBandwidth,
            points: bytesByDate.map {
                ChartPoint(date: $0.key, series: String(localized: .statsBandwidth), value: Double($0.value))
            }
            .sorted { $0.date < $1.date },
            range: range,
            style: .line,
            tint: .blue,
            valueFormatter: { Int($0).byteFormatted }
        )
    }
}
