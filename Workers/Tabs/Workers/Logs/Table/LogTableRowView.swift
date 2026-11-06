import SwiftUI

struct LogTableRowView: View {
    let row: LogTableRow
    let columns: [LogTableColumn]
    let widths: [LogTableColumn: CGFloat]
    let columnSpacing: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: columnSpacing) {
                ForEach(columns) { column in
                    cell(for: column)
                        .lineLimit(1)
                        .frame(width: widths[column], alignment: .leading)
                }
            }
            .font(.footnote)
            .padding(.horizontal, LogTableView.horizontalPadding)
            .padding(.vertical, 12)
            Divider()
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func cell(for column: LogTableColumn) -> some View {
        let value = row.values[column] ?? ""
        switch column {
        case .status:
            HStack(spacing: 4) {
                Image(systemName: row.severity.symbol)
                    .symbolRenderingMode(.multicolor)
                    .accessibilityLabel(row.severity.accessibilityLabel)
                Text(value)
                    .foregroundStyle(.secondary)
            }
        case .message:
            Text(value)
        default:
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
