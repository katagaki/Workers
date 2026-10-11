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
                Text(snapshot.requests > 0 ? snapshot.successRate.formatted(.percent.precision(.fractionLength(1))) : String(localized: .widgetsNoTraffic))
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
                content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: hasChart ? .topLeading : .leading)
                HStack {
                    if family != .systemSmall { Text(.widgetsPastDay) }
                    Spacer()
                    Text(snapshot.date, style: .time)
                }.font(.caption2).foregroundStyle(.secondary)
            }
            .padding(16)
            .background {
                if hasChart { WorkerWidgetAreaChart(snapshot: snapshot) }
            }
            .clipped()
        }
    }

    private var hasChart: Bool { [.traffic, .trend, .overview].contains(design) }

    @ViewBuilder private var content: some View {
        switch design {
        case .traffic:
            metric(.widgetsRequests, value: snapshot.requests.formatted(.number.notation(.compactName)))
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
            metric(.widgetsRequests, value: snapshot.requests.formatted(.number.notation(.compactName)))
            Text(.widgetsErrorsValue(snapshot.errors)).font(.caption).foregroundStyle(.secondary)
        case .overview:
            HStack(alignment: .top) {
                metric(.widgetsRequests, value: snapshot.requests.formatted(.number.notation(.compactName)))
                Spacer()
                metric(.widgetsErrors, value: snapshot.errors.formatted(.number.notation(.compactName)))
            }
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

}
