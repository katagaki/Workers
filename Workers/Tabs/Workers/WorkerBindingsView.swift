import CloudflareKit
import SwiftUI

struct WorkerBindingsView: View {
    let client: CloudflareClient
    let accountId: String
    let scriptName: String

    @State private var settings: CachedResource<WorkerSettings>

    init(client: CloudflareClient, accountId: String, scriptName: String) {
        self.client = client
        self.accountId = accountId
        self.scriptName = scriptName
        _settings = State(initialValue: CachedResource(key: "worker-settings-\(accountId)-\(scriptName)"))
    }

    private var groupedBindings: [(String, [WorkerBinding])] {
        let bindings = settings.value?.bindings ?? []
        return Dictionary(grouping: bindings, by: \.typeTitle)
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        List {
            ForEach(groupedBindings, id: \.0) { title, bindings in
                Section(title) {
                    ForEach(bindings, id: \.bindingIdentifier) { binding in
                        if let destination = storageDestination(for: binding) {
                            NavigationLink(value: destination) {
                                bindingLabel(binding)
                            }
                        } else {
                            bindingLabel(binding)
                        }
                    }
                }
            }
            if let flags = settings.value?.compatibilityFlags, !flags.isEmpty {
                Section(.workersBindingsCompatibilityFlags) {
                    ForEach(flags, id: \.self) { flag in
                        Text(flag)
                    }
                }
            }
        }
        .navigationTitle(.workersBindingsTitle)
        .resourceStatus(
            settings,
            emptyTitle: .workersBindingsEmpty,
            emptySystemImage: "link",
            isEmpty: { ($0.bindings ?? []).isEmpty && ($0.compatibilityFlags ?? []).isEmpty }
        )
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func reload() async {
        await settings.refresh {
            try await client.workerSettings(accountId: accountId, scriptName: scriptName)
        }
    }

    private func bindingLabel(_ binding: WorkerBinding) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(binding.name)
                .font(.body.weight(.medium))
            if let detail = binding.detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }
        }
    }

    private func storageDestination(for binding: WorkerBinding) -> StorageDestination? {
        switch binding.type {
        case "kv_namespace":
            binding.namespaceId.map { .kvNamespace(namespaceId: $0, title: binding.name) }
        case "r2_bucket":
            binding.bucketName.map { .r2Bucket(bucketName: $0, prefix: "") }
        case "d1":
            (binding.databaseId ?? binding.id).map { .d1Database(databaseId: $0, name: binding.name, database: nil) }
        default:
            nil
        }
    }
}
