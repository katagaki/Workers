import SwiftUI
import WidgetKit

extension WorkerWidgetView {
    @ViewBuilder var content: some View {
        switch design {
        case .traffic:
            metric(.widgetsRequests, value: requests)
        case .reliability:
            HStack(spacing: 20) {
                Gauge(value: snapshot.successRate) { Text(.widgetsSuccess) }
                    currentValueLabel: { Text(successRate) }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .tint(successColor)
                    .font(.body)
                if family != .systemSmall {
                    VStack(alignment: .leading, spacing: 4) {
                        metric(.widgetsRequests, value: requests)
                        Text(.widgetsErrorsValue(snapshot.errors)).foregroundStyle(.secondary)
                    }
                }
            }
        case .trend:
            VStack(alignment: .leading, spacing: 4) {
                metric(.widgetsRequests, value: requests)
                Text(.widgetsErrorsValue(snapshot.errors)).foregroundStyle(.secondary)
            }
        case .overview:
            HStack(alignment: .top) {
                metric(.widgetsRequests, value: requests)
                Spacer()
                metric(.widgetsErrors, value: errors)
            }
        case .compact:
            HStack(alignment: .top, spacing: 16) {
                metric(.widgetsRequests, value: requests)
                Spacer(minLength: 0)
                metric(.widgetsErrors, value: errors)
                if family != .systemSmall {
                    Spacer(minLength: 0)
                    metric(.widgetsSuccess, value: successRate)
                }
            }
        }
    }

    private var requests: String { snapshot.requests.formatted(.number.notation(.compactName)) }
    private var errors: String { snapshot.errors.formatted(.number.notation(.compactName)) }
    private var successRate: String {
        snapshot.requests > 0
            ? snapshot.successRate.formatted(.percent.precision(.fractionLength(1)))
            : String(localized: .widgetsNoTraffic)
    }

    private func metric(_ title: LocalizedStringResource, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.body).foregroundStyle(.secondary)
            Text(verbatim: value)
                .font(.title2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
