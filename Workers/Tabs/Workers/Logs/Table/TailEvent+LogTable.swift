import CloudflareKit
import SwiftUI

extension TailEvent {
    static let logTableColumns: [LogTableColumn] = [
        .time, .status, .method, .url, .message, .outcome, .country, .dataCenter
    ]

    var logTableRow: LogTableRow {
        var values: [LogTableColumn: String] = [
            .time: date.formatted(.dateTime.hour().minute().second()),
            .message: message
        ]
        values[.status] = responseStatus.map(String.init)
        values[.method] = requestMethod
        values[.url] = requestURL?.urlPath
        values[.outcome] = outcome?.capitalizedFirst
        values[.country] = countryName
        values[.dataCenter] = dataCenter
        return LogTableRow(
            id: id.uuidString,
            destination: .tailEvent(self),
            severity: LogSeverity(isError: isError, statusCode: responseStatus),
            values: values
        )
    }
}
