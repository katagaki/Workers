import SwiftUI

struct AnalyticsBreakdownRow: View {
    let title: String
    let value: String
    var detail: String?
    var detailTint: Color = .secondary

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .lineLimit(1)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(detailTint)
                }
            }
        }
    }
}
