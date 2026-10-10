import CloudflareKit
import SwiftUI

struct WorkersListView: View {
    @Environment(CloudflareSession.self) private var session
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
                if let account = session.selectedAccount {
                    WorkersUsageSection(
                        client: resources.client,
                        account: account,
                        tokenName: session.savedTokens.first { $0.id == session.selectedTokenId }?.name
                    )
                }
                RefreshErrorSection(resource: resources.scripts)
                Section(.tabsWorkers) {
                    workersStatus
                    ForEach(filteredScripts) { script in
                        NavigationLink(value: script) {
                            WorkerRow(script: script, requests: requestCounts[script.name])
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(.tabsWorkers)
            .accountToolbar()
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(.workersSearch))
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

    @ViewBuilder
    private var workersStatus: some View {
        if resources.scripts.value == nil, resources.scripts.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else if resources.scripts.value == nil, let error = resources.scripts.error {
            ContentUnavailableView {
                Label(.sharedCouldntLoad, systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.localizedDescription)
            }
        } else if resources.scripts.value?.isEmpty == true {
            ContentUnavailableView {
                Label(.workersEmptyTitle, systemImage: "hammer")
            } description: {
                Text(.workersEmptyMessage)
            }
        }
    }
}
