import CloudflareKit
import SwiftUI

extension ObservabilityEvent {
    static let logTableColumns: [LogTableColumn] = [
        .time, .status, .message, .trigger, .outcome, .cpuTime, .wallTime, .url
    ]

    var logTableRow: LogTableRow {
        var values: [LogTableColumn: String] = [
            .time: date.formatted(.dateTime.hour().minute().second()),
            .message: summary.isEmpty ? String(localized: .logsNoMessage) : summary
        ]
        values[.status] = metadata.statusCode.map { String(Int($0)) }
        values[.trigger] = workers?.eventType?.capitalizedFirst
        values[.outcome] = workers?.outcome?.capitalizedFirst
        values[.cpuTime] = workers?.cpuTimeMs?.millisecondsFormatted
        values[.wallTime] = workers?.wallTimeMs?.millisecondsFormatted
        values[.url] = metadata.url?.urlPath
        return LogTableRow(
            id: id,
            destination: .observabilityEvent(self),
            severity: LogSeverity(isError: isError, statusCode: metadata.statusCode.map { Int($0) }),
            values: values
        )
    }
}
