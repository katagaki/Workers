import Charts
import SwiftUI
import WidgetKit

struct WorkerWidgetView: View {
    let snapshot: WorkerWidgetSnapshot
    let design: WorkerWidgetDesign
    var family: WidgetFamily = .systemMedium

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("\(snapshot.worker.name): \(snapshot.requests.formatted(.number.notation(.compactName)))")
        case .accessoryCircular:
            Gauge(value: snapshot.successRate) {
                Image(systemName: "hammer")
            } currentValueLabel: {
                Text(snapshot.requests > 0 ? snapshot.successRate.formatted(.percent.precision(.fractionLength(0))) : String(localized: .widgetsNoTraffic))
            }.gaugeStyle(.accessoryCircular)
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Text(verbatim: snapshot.worker.name).font(.headline).lineLimit(1)
                Text(.widgetsRequestsValue(snapshot.requests)).font(.caption)
                Text(snapshot.date, style: .time).font(.caption2)
            }
        default:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "hammer").foregroundStyle(.secondary)
                    Text(verbatim: snapshot.worker.name).font(.caption.weight(.semibold)).lineLimit(1)
                }
                content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                HStack {
                    Text(.widgetsPastDay)
                    Spacer()
                    Text(snapshot.date, style: .time)
                }.font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch design {
        case .traffic:
            metric(.widgetsRequests, value: snapshot.requests.formatted(.number.notation(.compactName)))
            sparkline
        case .reliability:
            HStack(spacing: 16) {
                Gauge(value: snapshot.successRate) { Text(.widgetsSuccess) }
                    currentValueLabel: { Text(snapshot.requests > 0 ? snapshot.successRate.formatted(.percent.precision(.fractionLength(1))) : String(localized: .widgetsNoTraffic)) }
                    .gaugeStyle(.accessoryCircular).tint(.primary)
                if family != .systemSmall {
                    VStack(alignment: .leading, spacing: 8) {
                        metric(.widgetsRequests, value: snapshot.requests.formatted(.number.notation(.compactName)))
                        Text(.widgetsErrorsValue(snapshot.errors)).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        case .trend:
            Text(.widgetsRequests).font(.caption).foregroundStyle(.secondary)
            Chart(snapshot.points) { point in
                BarMark(x: .value("", point.date), y: .value("", point.requests))
                    .foregroundStyle(.primary.opacity(0.65))
            }.chartXAxis(.hidden).chartYAxis(.hidden)
            Text(.widgetsErrorsValue(snapshot.errors)).font(.caption)
        case .overview:
            HStack(alignment: .top) {
                metric(.widgetsRequests, value: snapshot.requests.formatted(.number.notation(.compactName)))
                Spacer()
                metric(.widgetsErrors, value: snapshot.errors.formatted(.number.notation(.compactName)))
            }
            sparkline
        case .compact:
            LabeledContent(.widgetsRequests, value: snapshot.requests.formatted(.number.notation(.compactName)))
            Divider()
            LabeledContent(.widgetsErrors, value: snapshot.errors.formatted())
            if family != .systemSmall {
                Divider()
                LabeledContent(.widgetsSuccess, value: snapshot.requests > 0 ? snapshot.successRate.formatted(.percent.precision(.fractionLength(2))) : String(localized: .widgetsNoTraffic))
            }
        }
    }

    private func metric(_ title: LocalizedStringResource, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(verbatim: value).font(family == .systemSmall ? .title2 : .title).fontWeight(.semibold).minimumScaleFactor(0.6).lineLimit(1)
        }
    }

    private var sparkline: some View {
        Chart(snapshot.points) { point in
            LineMark(x: .value("", point.date), y: .value("", point.requests))
                .interpolationMethod(.monotone).foregroundStyle(.primary)
        }.chartXAxis(.hidden).chartYAxis(.hidden)
    }
}
