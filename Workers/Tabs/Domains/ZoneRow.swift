import CloudflareKit
import SwiftUI

struct ZoneRow: View {
    let zone: Zone

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(zone.name)
                .font(.body.weight(.medium))
                .lineLimit(1)
            Label {
                Text(zone.subtitle)
            } icon: {
                Image(systemName: zone.statusSymbol)
                    .foregroundStyle(zone.statusColor)
            }
            .labelStyle(.compact)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
