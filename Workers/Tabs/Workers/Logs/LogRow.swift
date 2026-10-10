import SwiftUI

struct LogRow: View {
    let severity: LogSeverity
    let title: String
    let subtitle: String?
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.isEmpty ? String(localized: .logsNoMessage) : title)
                .font(.subheadline)
                .lineLimit(3)
            HStack(spacing: 4) {
                Image(systemName: severity.symbol)
                    .symbolRenderingMode(.multicolor)
                    .accessibilityLabel(severity.accessibilityLabel)
                if let subtitle {
                    Text(subtitle)
                    Text(verbatim: "·")
                }
                Text(date, format: .dateTime.hour().minute().second())
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
