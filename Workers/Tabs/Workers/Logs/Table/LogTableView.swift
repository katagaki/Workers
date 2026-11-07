import SwiftUI

struct LogTableView: View {
    let columns: [LogTableColumn]
    let rows: [LogTableRow]

    @ScaledMetric(relativeTo: .footnote) private var widthScale: CGFloat = 1
    @State private var viewportSize: CGSize = .zero

    private static let columnSpacing: CGFloat = 12
    static let horizontalPadding: CGFloat = 16

    private var columnWidths: [LogTableColumn: CGFloat] {
        var widths = Dictionary(uniqueKeysWithValues: columns.map { ($0, $0.width * widthScale) })
        let spacing = Self.columnSpacing * CGFloat(columns.count - 1)
        let usedWidth = widths.values.reduce(spacing + Self.horizontalPadding * 2, +)
        widths[.message, default: 0] += max(0, viewportSize.width - usedWidth)
        return widths
    }

    var body: some View {
        let widths = columnWidths
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    ForEach(rows) { row in
                        NavigationLink(value: row.destination) {
                            LogTableRowView(
                                row: row,
                                columns: columns,
                                widths: widths,
                                columnSpacing: Self.columnSpacing
                            )
                        }
                        .buttonStyle(LogTableRowButtonStyle())
                    }
                } header: {
                    if !rows.isEmpty {
                        header(widths: widths)
                    }
                }
            }
            .frame(minWidth: viewportSize.width, minHeight: viewportSize.height, alignment: .topLeading)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .onGeometryChange(for: CGSize.self, of: \.size) { viewportSize = $0 }
    }

    private func header(widths: [LogTableColumn: CGFloat]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: Self.columnSpacing) {
                ForEach(columns) { column in
                    Text(column.title)
                        .lineLimit(1)
                        .frame(width: widths[column], alignment: .leading)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, Self.horizontalPadding)
            .padding(.vertical, 8)
            Divider()
        }
        .background(.bar)
    }
}
