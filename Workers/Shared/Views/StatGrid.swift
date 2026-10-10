import SwiftUI

struct StatGrid: View {
    let stats: [Stat]

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
            ForEach(Array(stride(from: 0, to: stats.count, by: 2)), id: \.self) { rowStart in
                GridRow {
                    ForEach(stats[rowStart..<min(rowStart + 2, stats.count)]) { stat in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.title)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(stat.value)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(stat.tint)
                                .contentTransition(.numericText())
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
