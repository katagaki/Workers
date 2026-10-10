import CloudflareKit
import SwiftUI

struct NamespaceRow: View {
    let namespace: DurableObjectNamespace
    let requests: Int?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(namespace.displayName)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(namespace.storageBackendTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let requests {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(requests.compactFormatted)
                    Text(.statsRequests24Hours)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
