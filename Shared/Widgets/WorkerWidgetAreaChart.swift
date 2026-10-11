import Charts
import SwiftUI

struct WorkerWidgetAreaChart: View {
    let snapshot: WorkerWidgetSnapshot

    var body: some View {
        Chart(snapshot.points) { point in
            AreaMark(x: .value("", point.date), y: .value("", point.requests))
                .interpolationMethod(.monotone)
                .foregroundStyle(Color.accentColor.opacity(0.2))
            LineMark(x: .value("", point.date), y: .value("", point.requests))
                .interpolationMethod(.monotone)
                .foregroundStyle(Color.accentColor.opacity(0.45))
                .lineStyle(StrokeStyle(lineWidth: 1.5))
        }
        .chartXScale(domain: (snapshot.points.first?.date ?? snapshot.date.addingTimeInterval(-86400))...(snapshot.points.last?.date ?? snapshot.date))
        .chartYScale(domain: 0...max(1, snapshot.points.map(\.requests).max() ?? 1))
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { plot in plot.padding(.zero) }
        .accessibilityLabel(Text(.widgetsRequests))
        .allowsHitTesting(false)
    }
}
