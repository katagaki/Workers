import CloudflareKit
import SwiftUI

struct D1ResultSection: View {
    let result: D1QueryResult
    var footer: LocalizedStringResource?

    var body: some View {
        Section {
            ForEach(Array(result.rows.enumerated()), id: \.offset) { index, row in
                NavigationLink {
                    D1RowView(columns: result.columns, row: row, index: index)
                } label: {
                    D1RowSummary(columns: result.columns, row: row)
                }
            }
        } header: {
            Text(.storageD1Results(result.rows.count.formatted()))
        } footer: {
            if let footer {
                Text(footer)
            }
        }
    }
}

struct D1RowSummary: View {
    let columns: [String]
    let row: [JSONValue]

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(row.first?.displayText ?? "")
                .lineLimit(1)
            if row.count > 1 {
                Text(zip(columns.dropFirst(), row.dropFirst()).prefix(3).map { "\($0): \($1.displayText)" }.joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
}
