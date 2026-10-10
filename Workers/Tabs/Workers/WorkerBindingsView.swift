import CloudflareKit
import SwiftUI

struct WorkerBindingsView: View {
    let client: CloudflareClient
    let accountId: String
    let settings: CachedResource<WorkerSettings>

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
                            NavigationLink {
                                destination
                            } label: {
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

    @ViewBuilder
    private func storageDestination(for binding: WorkerBinding) -> (some View)? {
        switch binding.type {
        case "kv_namespace":
            if let namespaceId = binding.namespaceId {
                KVNamespaceView(client: client, accountId: accountId, namespaceId: namespaceId, title: binding.name)
            }
        case "r2_bucket":
            if let bucketName = binding.bucketName {
                R2BucketView(client: client, accountId: accountId, bucketName: bucketName)
            }
        case "d1":
            if let databaseId = binding.databaseId ?? binding.id {
                D1DatabaseView(client: client, accountId: accountId, databaseId: databaseId, name: binding.name)
            }
        default:
            EmptyView()
        }
    }
}
