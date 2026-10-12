import SwiftUI
import WidgetKit

struct WorkerWidgetEmptyView: View {
    let needsConfiguration: Bool
    let family: WidgetFamily

    private var title: LocalizedStringResource {
        needsConfiguration ? .widgetsConfigure : .widgetsUnavailableTitle
    }

    var body: some View {
        switch family {
        case .accessoryInline:
            Label(title, systemImage: "hammer")
        case .accessoryCircular:
            Image(systemName: "hammer")
                .font(.title2)
                .accessibilityLabel(Text(title))
        case .accessoryRectangular:
            Label(title, systemImage: "hammer")
                .font(.headline)
        default:
            VStack(spacing: 8) {
                Image(systemName: "hammer")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.headline)
                Text(needsConfiguration ? .widgetsConfigureMessage : .widgetsUnavailable)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(16)
        }
    }
}
