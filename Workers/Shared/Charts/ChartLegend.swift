import SwiftUI

struct ChartLegend: View {
    let entries: [(name: String, color: Color, value: String?)]

    var body: some View {
        FlowLayout(horizontalSpacing: 12, verticalSpacing: 4) {
            ForEach(entries, id: \.name) { entry in
                HStack(spacing: 5) {
                    Circle()
                        .fill(entry.color)
                        .frame(width: 8, height: 8)
                    Text(entry.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if let value = entry.value {
                        Text(value)
                            .font(.caption.weight(.medium))
                    }
                }
            }
        }
    }
}
