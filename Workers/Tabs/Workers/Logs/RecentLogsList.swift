import CloudflareKit
import SwiftUI

struct RecentLogsList: View {
    let client: CloudflareClient
    let accountId: String
    let scriptName: String
    let window: LogWindow
    let searchText: String

    @State private var events: CachedResource<[ObservabilityEvent]>

    init(client: CloudflareClient, accountId: String, scriptName: String, window: LogWindow, searchText: String) {
        self.client = client
        self.accountId = accountId
        self.scriptName = scriptName
        self.window = window
        self.searchText = searchText
        _events = State(initialValue: CachedResource(key: "worker-events-\(accountId)-\(scriptName)-\(window.rawValue)"))
    }

    private var filteredEvents: [ObservabilityEvent] {
        let all = events.value ?? []
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.summary.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            RefreshErrorSection(resource: events)
            ForEach(filteredEvents) { event in
                NavigationLink(value: WorkersDestination.observabilityEvent(event)) {
                    LogRow(
                        severity: LogSeverity(isError: event.isError, statusCode: event.metadata.statusCode.map { Int($0) }),
                        title: event.summary,
                        subtitle: event.workers?.eventType?.capitalizedFirst,
                        date: event.date
                    )
                }
            }
        }
        .resourceStatus(
            events,
            emptyTitle: .logsEmptyTitle,
            emptySystemImage: "text.alignleft",
            emptyDescription: .logsEmptyMessage
        )
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func reload() async {
        await events.refresh {
            try await client.workerEvents(
                accountId: accountId,
                scriptName: scriptName,
                from: .now.addingTimeInterval(-window.duration),
                to: .now
            )
        }
    }
}
