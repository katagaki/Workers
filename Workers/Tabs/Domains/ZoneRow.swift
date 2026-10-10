import CloudflareKit
import SwiftUI

struct ZoneRow: View {
    let zone: Zone

    var body: some View {
        HStack(spacing: 12) {
            ZoneStatusIcon(zone: zone)
            VStack(alignment: .leading, spacing: 3) {
                Text(zone.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(zone.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
