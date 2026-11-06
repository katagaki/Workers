import CloudflareKit
import SwiftUI

struct WorkerLogsView: View {
    let client: CloudflareClient
    let accountId: String
    let scriptName: String

    @State private var mode: LogMode = .recent
    @State private var queryText = ""

    var body: some View {
        Group {
            switch mode {
            case .recent:
                RecentLogsView(client: client, accountId: accountId, scriptName: scriptName)
            case .query:
                LogQueryView(client: client, accountId: accountId, scriptName: scriptName, queryText: $queryText)
            case .live:
                LiveTailView(client: client, accountId: accountId, scriptName: scriptName)
            }
        }
        .safeAreaInset(edge: .top) {
            Picker(.logsSource, selection: $mode) {
                Text(.logsRecent).tag(LogMode.recent)
                Text(.logsQuery).tag(LogMode.query)
                Text(.logsLive).tag(LogMode.live)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationTitle(.logsTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
