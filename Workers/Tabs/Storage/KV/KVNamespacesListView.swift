import CloudflareKit
import SwiftUI

struct KVNamespacesListView: View {
    let client: CloudflareClient
    let accountId: String
    let namespaces: CachedResource<[KVNamespace]>

    @State private var searchText = ""

    private var filteredNamespaces: [KVNamespace] {
        let all = (namespaces.value ?? []).sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            RefreshErrorSection(resource: namespaces)
            ForEach(filteredNamespaces) { namespace in
                NavigationLink(value: StorageDestination.kvNamespace(namespaceId: namespace.id, title: namespace.title)) {
                    Text(namespace.title)
                        .lineLimit(1)
                }
            }
        }
        .navigationTitle(.storageKvTitle)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(.storageKvSearch))
        .resourceStatus(
            namespaces,
            emptyTitle: .storageKvEmptyTitle,
            emptySystemImage: "key",
            emptyDescription: .storageKvEmptyMessage
        )
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func reload() async {
        await namespaces.refresh {
            try await client.kvNamespaces(accountId: accountId)
        }
    }
}
