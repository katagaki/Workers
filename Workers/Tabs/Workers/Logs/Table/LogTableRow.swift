import Foundation

struct LogTableRow: Identifiable {
    let id: String
    let destination: WorkersDestination
    let severity: LogSeverity
    let values: [LogTableColumn: String]
}
