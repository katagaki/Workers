import CloudflareKit
import SwiftUI

struct WorkerVersionsView: View {
    let client: CloudflareClient
    let accountId: String
    let scriptName: String

    @State private var versions: CachedResource<[WorkerVersion]>
    @State private var pendingAction: WorkerDeploymentAction?

    init(client: CloudflareClient, accountId: String, scriptName: String) {
        self.client = client
        self.accountId = accountId
        self.scriptName = scriptName
        _versions = State(initialValue: CachedResource(key: "worker-versions-\(accountId)-\(scriptName)"))
    }

    private var sortedVersions: [WorkerVersion] {
        (versions.value ?? []).sorted { ($0.number ?? 0) > ($1.number ?? 0) }
    }

    var body: some View {
        List {
            RefreshErrorSection(resource: versions)
            ForEach(sortedVersions) { version in
                VersionRow(version: version)
                Button(.workersDeploymentRedeploy) {
                    pendingAction = WorkerDeploymentAction(version: version)
                }
            }
        }
        .navigationTitle(.workersVersionsTitle)
        .resourceStatus(versions, emptyTitle: .workersVersionsEmpty, emptySystemImage: "clock.arrow.circlepath")
        .task { await reload() }
        .refreshable { await reload() }
        .sheet(item: $pendingAction) { action in
            WorkerDeploymentConfirmation(client: client, accountId: accountId, scriptName: scriptName,
                action: action, onDeployed: reload)
        }
    }

    private func reload() async {
        await versions.refresh {
            try await client.workerVersions(accountId: accountId, scriptName: scriptName)
        }
    }
}
