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
                Text(.widgetsSuccess)
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
            VStack(alignment: .leading, spacing: 0) {
                WorkerWidgetTitleBar(name: snapshot.worker.name)
                VStack(alignment: .leading, spacing: 4) {
                    content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    Text(snapshot.date, style: .time)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .accessibilityLabel(Text(.widgetsPastDay))
                        .accessibilityValue(Text(snapshot.date, style: .time))
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background {
                    if hasChart { WorkerWidgetAreaChart(snapshot: snapshot) }
                }
                .clipped()
            }
            .font(.body)
            .clipped()
        }
    }

    var hasChart: Bool { [.traffic, .trend, .overview].contains(design) }

    private var workerName: some View {
        Text(verbatim: snapshot.worker.name)
            .font(.body)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    var successColor: Color {
        guard snapshot.requests > 0 else { return .secondary }
        if snapshot.successRate >= 0.99 { return .green }
        if snapshot.successRate >= 0.95 { return .orange }
        return .red
    }

}
