import CloudflareKit
import SwiftUI

struct RecentLogsView: View {
    let client: CloudflareClient
    let accountId: String
    let scriptName: String

    @AppStorage("RecentLogsWindow") private var window: LogWindow = .hour
    @State private var searchText = ""

    var body: some View {
        RecentLogsList(
            client: client,
            accountId: accountId,
            scriptName: scriptName,
            window: window,
            searchText: searchText
        )
        .id(window)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(.logsFilter))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                LogWindowMenu(window: $window)
            }
        }
    }
}
