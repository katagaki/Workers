import CloudflareKit
import SwiftUI

struct LogQueryResultsSections: View {
    let events: [ObservabilityEvent]?
    let queryError: String?

    var body: some View {
        if let queryError {
            Section {
                Label {
                    Text(queryError)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
        }
        if let events, events.isEmpty {
            Section {
                Text(.logsQueryNoResults)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
