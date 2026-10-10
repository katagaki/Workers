import CloudflareKit
import SwiftUI

struct WorkersListView: View {
    let client: CloudflareClient
    let accountId: String

    @State private var scripts: CachedResource<[WorkerScript]>
    @State private var analytics: CachedResource<[WorkerAnalyticsPoint]>
    @State private var searchText = ""
    @State private var selection: WorkerScript?
    private let navigator = AppNavigator.shared

    init(client: CloudflareClient, accountId: String) {
        self.client = client
        self.accountId = accountId
        _scripts = State(initialValue: CachedResource(key: "workers-\(accountId)"))
        _analytics = State(initialValue: CachedResource(key: "workers-analytics-\(accountId)-day"))
    }

    private var filteredScripts: [WorkerScript] {
        let all = (scripts.value ?? []).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var requestCounts: [String: Int] {
        (analytics.value ?? []).reduce(into: [:]) { counts, point in
            counts[point.scriptName, default: 0] += point.requests
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                RefreshErrorSection(resource: scripts)
                ForEach(filteredScripts) { script in
                    NavigationLink(value: script) {
                        WorkerRow(script: script, requests: requestCounts[script.name])
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle(.tabsWorkers)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(.workersSearch))
            .resourceStatus(
                scripts,
                emptyTitle: .workersEmptyTitle,
                emptySystemImage: "hammer",
                emptyDescription: .workersEmptyMessage
            )
            .onChange(of: navigator.pendingRequest, initial: true) { _, request in
                guard let request, request.accountId == accountId,
                      case .worker(let script) = request.destination else { return }
                selection = script
                navigator.pendingRequest = nil
            }
            .task { await reload() }
            .refreshable { await reload() }
        } detail: {
            if let selection {
                NavigationStack {
                    WorkerDetailView(client: client, accountId: accountId, script: selection) {
                        scripts.update { $0.removeAll { $0.id == selection.id } }
                        self.selection = nil
                    }
                }
                .id(selection.id)
            } else {
                ContentUnavailableView(.workersNoSelection, systemImage: "hammer")
            }
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
