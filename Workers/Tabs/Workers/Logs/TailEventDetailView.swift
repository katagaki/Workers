import CloudflareKit
import SwiftUI

struct TailEventDetailView: View {
    let event: TailEvent

    var body: some View {
        List {
            Section(.logsEventRequest) {
                LabeledContent(.sharedTime, value: event.date.formatted(date: .abbreviated, time: .standard))
                if let outcome = event.outcome {
                    LabeledContent(.sharedOutcome, value: outcome.capitalizedFirst)
                }
                if let method = event.requestMethod {
                    LabeledContent(.logsEventMethod, value: method)
                }
                if let status = event.responseStatus {
                    LabeledContent(.sharedStatus, value: String(status))
                }
                if let url = event.requestURL {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(.sharedUrl)
                        Text(url)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
                if let cron = event.cron {
                    LabeledContent(.logsEventCron, value: cron)
                }
                if let country = event.event?["request"]?["cf"]?["country"]?.stringValue {
                    LabeledContent(.logsEventCountry, value: Locale.current.localizedString(forRegionCode: country) ?? country)
                }
                if let colo = event.event?["request"]?["cf"]?["colo"]?.stringValue {
                    LabeledContent(.logsEventDataCenter, value: colo)
                }
            }
            if let exceptions = event.exceptions, !exceptions.isEmpty {
                Section(.logsEventExceptions) {
                    ForEach(Array(exceptions.enumerated()), id: \.offset) { _, exception in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(exception.name ?? String(localized: .sharedError))
                                .font(.body.weight(.medium))
                                .foregroundStyle(.red)
                            if let message = exception.message {
                                Text(message)
                                    .font(.subheadline)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
            }
            if let logs = event.logs, !logs.isEmpty {
                Section(.logsEventConsole) {
                    ForEach(Array(logs.enumerated()), id: \.offset) { _, log in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(log.text)
                                .font(.subheadline)
                                .textSelection(.enabled)
                            if let level = log.level {
                                Text(level.capitalizedFirst)
                                    .font(.caption)
                                    .foregroundStyle(level == "error" ? .red : .secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(.logsEventRequest)
        .navigationBarTitleDisplayMode(.inline)
    }
}
