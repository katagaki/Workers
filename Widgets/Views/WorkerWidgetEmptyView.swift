import SwiftUI
import WidgetKit

struct WorkerWidgetEmptyView: View {
    let needsConfiguration: Bool
    let family: WidgetFamily

    private var title: LocalizedStringResource {
        needsConfiguration ? .widgetsConfigure : .widgetsUnavailableTitle
    }

    private var message: LocalizedStringResource {
        needsConfiguration ? .widgetsConfigureMessage : .widgetsUnavailable
    }

    var body: some View {
        switch family {
        case .accessoryInline:
            Label(title, systemImage: "hammer")
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "hammer")
                    .font(.title3)
            }
            .accessibilityElement()
            .accessibilityLabel(Text(title))
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(alignment: .leading, spacing: 0) {
                WorkerWidgetTitleBar(title)
                Text(message)
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .font(.body)
        }
    }
}
