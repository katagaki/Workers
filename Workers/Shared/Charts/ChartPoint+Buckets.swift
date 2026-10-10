import CloudflareKit
import Foundation

extension Array where Element == ChartPoint {
    // Stacked areas interpolate across missing buckets and misalign between series, so every series needs a value in every bucket.
    func filledBuckets(for range: AnalyticsRange, seriesNames: [String], calendar: Calendar = .current) -> [ChartPoint] {
        guard !isEmpty else { return self }
        let component = range.bucketComponent
        func bucketStart(of date: Date) -> Date {
            calendar.dateInterval(of: component, for: date)?.start ?? date
        }

        var values: [String: [Date: Double]] = [:]
        for point in self {
            values[point.series, default: [:]][bucketStart(of: point.date), default: 0] += point.value
        }

        let latest = Swift.max(map(\.date).max() ?? .now, .now)
        let earliest = Swift.min(map(\.date).min() ?? latest, range.interval(endingAt: latest).start)
        let lastBucket = bucketStart(of: latest)
        var buckets: [Date] = []
        var bucket = bucketStart(of: earliest)
        while bucket <= lastBucket {
            buckets.append(bucket)
            guard let next = calendar.date(byAdding: component, value: 1, to: bucket), next > bucket else { break }
            bucket = next
        }

        return seriesNames.flatMap { name in
            buckets.map { date in
                ChartPoint(date: date, series: name, value: values[name]?[date] ?? 0)
            }
        }
    }
}
