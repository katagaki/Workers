import Charts
import CloudflareKit
import SwiftUI

struct SeriesChart: View {
    enum Style {
        case area
        case line
        case bar
    }

    struct Series {
        let name: String
        let color: Color
    }

    var title: LocalizedStringResource?
    let points: [ChartPoint]
    let range: AnalyticsRange
    var style: Style = .area
    var tint: Color? = nil
    var series: [Series] = []
    var showsLegendTotals = false
    var valueFormatter: (Double) -> String = { Int($0).compactFormatted }

    private static let maximumSeries = 6
    private static let otherSeries = String(localized: .sharedOther)

    private var foldedPoints: [ChartPoint] {
        var totals: [String: Double] = [:]
        for point in points {
            totals[point.series, default: 0] += point.value
        }
        guard totals.count > Self.maximumSeries else { return points }
        let kept = Set(totals.sorted { $0.value > $1.value }.prefix(Self.maximumSeries - 1).map(\.key))
        var merged: [Date: Double] = [:]
        var result: [ChartPoint] = []
        for point in points {
            if kept.contains(point.series) {
                result.append(point)
            } else {
                merged[point.date, default: 0] += point.value
            }
        }
        result += merged.map { ChartPoint(date: $0.key, series: Self.otherSeries, value: $0.value) }
        return result
    }

    private var seriesNames: [String] {
        if !series.isEmpty { return series.map(\.name) }
        let names = Set(foldedPoints.map(\.series))
        let sorted = names.subtracting([Self.otherSeries]).sorted()
        return names.contains(Self.otherSeries) ? sorted + [Self.otherSeries] : sorted
    }

    private var showsLegend: Bool {
        seriesNames.count > 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            if points.isEmpty {
                Text(.sharedNoDataForPeriod)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                chart
                if showsLegend {
                    ChartLegend(entries: Array(zip(seriesNames, palette)).map { name, color in
                        (name: name, color: color, value: showsLegendTotals ? valueFormatter(total(of: name)) : nil)
                    })
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var chart: some View {
        Chart(foldedPoints.filledBuckets(for: range, seriesNames: seriesNames)) { point in
            switch style {
            case .area:
                AreaMark(
                    x: .value("Time", point.date, unit: range.bucketComponent),
                    y: .value("Value", point.value),
                    stacking: .standard
                )
                .foregroundStyle(by: .value("Series", point.series))
            case .line:
                LineMark(
                    x: .value("Time", point.date, unit: range.bucketComponent),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(by: .value("Series", point.series))
            case .bar:
                BarMark(
                    x: .value("Time", point.date, unit: range.bucketComponent),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(by: .value("Series", point.series))
            }
        }
        .chartForegroundStyleScale(domain: seriesNames, range: palette)
        .chartLegend(.hidden)
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let number = value.as(Double.self) {
                        Text(valueFormatter(number))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                AxisValueLabel(format: range == .day ? .dateTime.hour() : .dateTime.month(.abbreviated).day())
            }
        }
        .frame(height: 180)
    }

    private func total(of seriesName: String) -> Double {
        foldedPoints.filter { $0.series == seriesName }.reduce(0) { $0 + $1.value }
    }

    private var palette: [Color] {
        if !series.isEmpty { return series.map(\.color) }
        if let tint, seriesNames.count == 1 {
            return [tint]
        }
        let hues: [Color] = [.orange, .blue, .green, .purple, .teal, .indigo]
        return seriesNames.enumerated().map { index, name in
            name == Self.otherSeries ? .gray : hues[index % hues.count]
        }
    }
}
