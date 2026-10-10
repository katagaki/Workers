import CloudflareKit
import SwiftUI

struct WorkersListView: View {
    let resources: AccountResources

    @State private var searchText = ""
    @State private var path = NavigationPath()
    private let navigator = AppNavigator.shared

    private var filteredScripts: [WorkerScript] {
        guard !searchText.isEmpty else { return resources.sortedScripts }
        return resources.sortedScripts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var requestCounts: [String: Int] {
        (resources.workerAnalytics.value ?? []).reduce(into: [:]) { counts, point in
            counts[point.scriptName, default: 0] += point.requests
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                RefreshErrorSection(resource: resources.scripts)
                ForEach(filteredScripts) { script in
                    NavigationLink(value: script) {
                        WorkerRow(script: script, requests: requestCounts[script.name])
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(.tabsWorkers)
            .accountToolbar()
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(.workersSearch))
            .resourceStatus(
                resources.scripts,
                emptyTitle: .workersEmptyTitle,
                emptySystemImage: "hammer",
                emptyDescription: .workersEmptyMessage
            )
            .navigationDestination(for: WorkerScript.self) { script in
                WorkerDetailView(client: resources.client, accountId: resources.accountId, script: script) {
                    resources.removeScript(script)
                }
                .navigationBarTitleDisplayMode(.inline)
            }
            .navigationDestination(for: WorkersDestination.self) { destination in
                destination.view(client: resources.client, accountId: resources.accountId)
            }
            .navigationDestination(for: StorageDestination.self) { destination in
                destination.view(client: resources.client, accountId: resources.accountId)
            }
            .onChange(of: navigator.pendingRequest, initial: true) { _, request in
                guard let request, request.accountId == resources.accountId,
                      case .worker(let script) = request.destination else { return }
                path = NavigationPath([script])
                navigator.pendingRequest = nil
            }
            .task { await resources.reloadWorkers() }
            .refreshable { await resources.reloadWorkers() }
        }
    }
}
