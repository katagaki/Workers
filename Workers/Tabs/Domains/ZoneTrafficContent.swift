import CloudflareKit
import SwiftUI

struct ZoneTrafficContent: View {
    let points: [ZoneAnalyticsPoint]
    let range: AnalyticsRange

    private var requests: Int { points.reduce(0) { $0 + $1.requests } }
    private var cachedRequests: Int { points.reduce(0) { $0 + $1.cachedRequests } }
    private var bytes: Int { points.reduce(0) { $0 + $1.bytes } }
    private var threats: Int { points.reduce(0) { $0 + $1.threats } }
    private var uniqueVisitors: Int { points.reduce(0) { $0 + $1.uniqueVisitors } }

    private var groupedByDate: [Date: (cached: Int, uncached: Int, bytes: Int)] {
        points.reduce(into: [:]) { result, point in
            let existing = result[point.date] ?? (0, 0, 0)
            result[point.date] = (
                existing.cached + point.cachedRequests,
                existing.uncached + point.requests - point.cachedRequests,
                existing.bytes + point.bytes
            )
        }
    }

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
        SeriesChart(
            title: .domainsRequestsByCacheStatus,
            points: groupedByDate.flatMap { date, totals in
                [
                    ChartPoint(date: date, series: String(localized: .statsCached), value: Double(totals.cached)),
                    ChartPoint(date: date, series: String(localized: .statsUncached), value: Double(totals.uncached))
                ]
            }
            .sorted { $0.date < $1.date },
            range: range
        )
        SeriesChart(
            title: .statsBandwidth,
            points: groupedByDate.map {
                ChartPoint(date: $0.key, series: String(localized: .statsBandwidth), value: Double($0.value.bytes))
            }
            .sorted { $0.date < $1.date },
            range: range,
            style: .line,
            tint: .blue,
            valueFormatter: { Int($0).byteFormatted }
        )
    }
}
