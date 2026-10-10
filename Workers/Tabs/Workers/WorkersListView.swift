import CloudflareKit
import SwiftUI

struct WorkersListView: View {
    let client: CloudflareClient
    let accountId: String

    @State private var scripts: CachedResource<[WorkerScript]>
    @State private var analytics: CachedResource<[WorkerAnalyticsPoint]>
    @State private var searchText = ""

    init(client: CloudflareClient, accountId: String) {
        self.client = client
        self.accountId = accountId
        _scripts = State(initialValue: CachedResource(key: "workers-\(accountId)"))
        _analytics = State(initialValue: CachedResource(key: "workers-analytics-\(accountId)-day"))
    }

    private var filteredScripts: [WorkerScript] {
        let all = (scripts.value ?? []).sorted {
            ($0.modifiedOn ?? .distantPast) > ($1.modifiedOn ?? .distantPast)
        }
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var requestCounts: [String: Int] {
        (analytics.value ?? []).reduce(into: [:]) { counts, point in
            counts[point.scriptName, default: 0] += point.requests
        }
    }

    var body: some View {
        NavigationStack {
            List {
                RefreshErrorSection(resource: scripts)
                ForEach(filteredScripts) { script in
                    NavigationLink(value: script) {
                        WorkerRow(script: script, requests: requestCounts[script.name])
                    }
                }
            }
            .navigationTitle(.tabsWorkers)
            .searchable(text: $searchText, prompt: Text(.workersSearch))
            .resourceStatus(
                scripts,
                emptyTitle: .workersEmptyTitle,
                emptySystemImage: "hammer",
                emptyDescription: .workersEmptyMessage
            )
            .navigationDestination(for: WorkerScript.self) { script in
                WorkerDetailView(client: client, accountId: accountId, script: script) {
                    scripts.update { $0.removeAll { $0.id == script.id } }
                }
            }
            .task { await reload() }
            .refreshable { await reload() }
        }
    }

    private func reload() async {
        async let scriptsLoad: Void = scripts.refresh {
            try await client.workerScripts(accountId: accountId)
        }
        async let analyticsLoad: Void = analytics.refresh {
            try await client.workerAnalytics(accountId: accountId, range: .day)
        }
        _ = await (scriptsLoad, analyticsLoad)
    }
}
