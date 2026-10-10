import CloudflareKit
import SwiftUI

struct WorkerRow: View {
    let script: WorkerScript
    let requests: Int?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(script.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                if let modifiedOn = script.modifiedOn {
                    Text(.workersUpdated(modifiedOn.relativeFormatted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let requests {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(requests.compactFormatted)
                        .font(.body)
                    Text(.statsRequests24Hours)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
