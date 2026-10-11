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
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(successColor)
            .font(.body)
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                workerName
                Text(.widgetsRequestsValue(snapshot.requests))
                Text(snapshot.date, style: .time)
            }.font(.body)
        default:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "hammer").foregroundStyle(.secondary)
                    workerName
                }
                content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: hasChart ? .topLeading : .leading)
                HStack {
                    if family != .systemSmall { Text(.widgetsPastDay) }
                    Spacer()
                    Text(snapshot.date, style: .time)
                }.foregroundStyle(.secondary)
            }
            .font(.body)
            .padding(16)
            .background {
                if hasChart { WorkerWidgetAreaChart(snapshot: snapshot) }
            }
            .clipped()
        }
    }

    private var hasChart: Bool { [.traffic, .trend, .overview].contains(design) }

    private var workerName: some View {
        Text(verbatim: snapshot.worker.name)
            .font(.body)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    private var successColor: Color {
        guard snapshot.requests > 0 else { return .secondary }
        if snapshot.successRate >= 0.99 { return .green }
        if snapshot.successRate >= 0.95 { return .orange }
        return .red
    }

    @ViewBuilder private var content: some View {
        switch design {
        case .traffic:
            metric(.widgetsRequests, value: snapshot.requests.formatted(.number.notation(.compactName)))
        case .reliability:
            HStack(spacing: 16) {
                Gauge(value: snapshot.successRate) { Text(.widgetsSuccess) }
                    currentValueLabel: { Text(snapshot.requests > 0 ? snapshot.successRate.formatted(.percent.precision(.fractionLength(1))) : String(localized: .widgetsNoTraffic)) }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .tint(successColor)
                    .font(.body)
                if family != .systemSmall {
                    VStack(alignment: .leading, spacing: 8) {
                        metric(.widgetsRequests, value: snapshot.requests.formatted(.number.notation(.compactName)))
                        Text(.widgetsErrorsValue(snapshot.errors)).foregroundStyle(.secondary)
                    }
                }
            }
        case .trend:
            metric(.widgetsRequests, value: snapshot.requests.formatted(.number.notation(.compactName)))
            Text(.widgetsErrorsValue(snapshot.errors)).foregroundStyle(.secondary)
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
            Text(title).font(.body).foregroundStyle(.secondary)
            Text(verbatim: value).font(family == .systemSmall ? .title2 : .title).fontWeight(.semibold).minimumScaleFactor(0.6).lineLimit(1)
        }
    }

}
