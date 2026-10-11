import CloudflareKit
import SwiftUI

struct WorkerDeploymentConfirmation: View {
    let client: CloudflareClient
    let accountId: String
    let scriptName: String
    let action: WorkerDeploymentAction
    let onDeployed: () async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isDeploying = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(scriptName).font(.headline)
                    ForEach(action.versions, id: \.versionId) { version in
                        Text(.workersDeploymentsVersionShare(version.percentage.formatted(), String(version.versionId.prefix(8))))
                    }
                } footer: {
                    Text(.workersDeploymentConfirmMessage)
                }
                Section {
                    Button(action.isRollback ? .workersDeploymentRollback : .workersDeploymentRedeploy, role: .destructive) {
                        Task { await deploy() }
                    }
                    .disabled(isDeploying)
                    if isDeploying { ProgressView() }
                    if let error { Text(error).foregroundStyle(.red) }
                } footer: {
                    Text(.workersDeploymentPermission)
                }
            }
            .navigationTitle(action.isRollback ? .workersDeploymentRollback : .workersDeploymentRedeploy)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.sharedCancel) { dismiss() }.disabled(isDeploying)
                }
            }
            .interactiveDismissDisabled(isDeploying)
        }
    }

    private func deploy() async {
        isDeploying = true
        error = nil
        defer { isDeploying = false }
        do {
            _ = try await client.deployWorkerVersions(accountId: accountId, scriptName: scriptName, versions: action.versions)
            DiskCache.shared.remove(for: "worker-deployments-\(accountId)-\(scriptName)")
            await onDeployed()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
