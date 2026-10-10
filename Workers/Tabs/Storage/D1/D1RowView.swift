import CloudflareKit
import SwiftUI

struct D1RowView: View {
    let columns: [String]
    let row: [JSONValue]
    let index: Int

    var body: some View {
        List {
            ForEach(Array(zip(columns, row).enumerated()), id: \.offset) { _, pair in
                LabeledContent(pair.0) {
                    Text(pair.1.displayText)
                        .foregroundStyle(pair.1 == .null ? .tertiary : .secondary)
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle(Text(.storageD1Row((index + 1).formatted())))
        .navigationBarTitleDisplayMode(.inline)
    }
}
