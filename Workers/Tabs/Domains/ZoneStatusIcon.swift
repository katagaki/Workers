import CloudflareKit
import SwiftUI

struct ZoneStatusIcon: View {
    let zone: Zone

    var body: some View {
        Image(systemName: zone.statusSymbol)
            .font(.title3)
            .foregroundStyle(zone.statusColor)
            .frame(width: 28)
            .accessibilityLabel(zone.statusTitle)
    }
}
