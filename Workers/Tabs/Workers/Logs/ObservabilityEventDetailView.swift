import CloudflareKit
import SwiftUI

struct ObservabilityEventDetailView: View {
    let event: ObservabilityEvent

    var body: some View {
        List {
            Section(.logsEventMessage) {
                Text(event.summary.isEmpty ? String(localized: .logsNoMessage) : event.summary)
                    .textSelection(.enabled)
            }
            if let error = event.metadata.error, !error.isEmpty {
                Section(.sharedError) {
                    Text(error)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
            }
            Section(.logsEventDetails) {
                LabeledContent(.sharedTime, value: event.date.formatted(date: .abbreviated, time: .standard))
                if let level = event.metadata.level {
                    LabeledContent(.logsEventLevel, value: level.capitalizedFirst)
                }
                if let eventType = event.workers?.eventType {
                    LabeledContent(.logsEventTrigger, value: eventType.capitalizedFirst)
                }
                if let outcome = event.workers?.outcome {
                    LabeledContent(.sharedOutcome, value: outcome.capitalizedFirst)
                }
                if let statusCode = event.metadata.statusCode {
                    LabeledContent(.sharedStatus, value: String(Int(statusCode)))
                }
                if let url = event.metadata.url {
                    LabeledContent(.sharedUrl, value: url)
                }
                if let cpuTime = event.workers?.cpuTimeMs {
                    LabeledContent(.logsEventCpuTime, value: cpuTime.millisecondsFormatted)
                }
                if let wallTime = event.workers?.wallTimeMs {
                    LabeledContent(.logsEventWallTime, value: wallTime.millisecondsFormatted)
                }
                if let requestId = event.workers?.requestId {
                    LabeledContent(.logsEventRequestID, value: requestId)
                        .textSelection(.enabled)
                }
            }
            if case .object(let fields) = event.source {
                Section(.logsEventFields) {
                    ForEach(fields.keys.sorted(), id: \.self) { key in
                        LabeledContent(key) {
                            Text(fields[key]?.displayText ?? "")
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
        .navigationTitle(.logsEventTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
