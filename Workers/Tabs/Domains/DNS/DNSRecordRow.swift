import CloudflareKit
import SwiftUI

struct DNSRecordRow: View {
    let record: DNSRecord
    let zoneName: String

    private var displayName: String {
        if record.name == zoneName { return "@" }
        if record.name.hasSuffix(".\(zoneName)") {
            return String(record.name.dropLast(zoneName.count + 1))
        }
        return record.name
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(record.type)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 56, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(displayName)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(record.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 8)
            if record.proxiable == true || record.proxied == true {
                Image(systemName: record.proxied == true ? "cloud.fill" : "cloud")
                    .foregroundStyle(record.proxied == true ? .orange : .secondary)
                    .accessibilityLabel(Text(record.proxied == true ? .dnsProxied : .dnsDnsOnly))
            }
        }
        .padding(.vertical, 2)
        .contentShape(.rect)
    }
}
