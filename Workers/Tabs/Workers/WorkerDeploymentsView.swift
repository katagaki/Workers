import CloudflareKit
import SwiftUI

struct WorkerDeploymentsView: View {
    let client: CloudflareClient
    let accountId: String
    let scriptName: String

    @State private var deployments: CachedResource<[WorkerDeployment]>

    init(client: CloudflareClient, accountId: String, scriptName: String) {
        self.client = client
        self.accountId = accountId
        self.scriptName = scriptName
        _deployments = State(initialValue: CachedResource(key: "worker-deployments-\(accountId)-\(scriptName)"))
    }

    private var sortedDeployments: [WorkerDeployment] {
        (deployments.value ?? []).sorted { $0.createdOn > $1.createdOn }
    }

    var body: some View {
        List {
            RefreshErrorSection(resource: deployments)
            ForEach(Array(sortedDeployments.enumerated()), id: \.element.id) { index, deployment in
                DeploymentRow(deployment: deployment, isActive: index == 0)
            }
        }
        .navigationTitle(.workersDeploymentsTitle)
        .resourceStatus(deployments, emptyTitle: .workersDeploymentsEmpty, emptySystemImage: "arrow.up.circle")
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func reload() async {
        await deployments.refresh {
            try await client.workerDeployments(accountId: accountId, scriptName: scriptName)
        }
    }
}
