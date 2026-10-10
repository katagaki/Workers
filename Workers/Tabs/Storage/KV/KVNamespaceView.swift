import CloudflareKit
import SwiftUI

struct KVNamespaceView: View {
    let client: CloudflareClient
    let accountId: String
    let namespaceId: String
    let title: String

    @State private var firstPage: CachedResource<KVKeyPage>
    @State private var prefixPage: KVKeyPage?
    @State private var additionalKeys: [KVKey] = []
    @State private var nextCursor: String?
    @State private var searchText = ""
    @State private var activePrefix = ""
    @State private var isLoadingMore = false
    @State private var loadError: String?

    init(client: CloudflareClient, accountId: String, namespaceId: String, title: String) {
        self.client = client
        self.accountId = accountId
        self.namespaceId = namespaceId
        self.title = title
        _firstPage = State(initialValue: CachedResource(key: "kv-keys-\(accountId)-\(namespaceId)"))
    }

    private var keys: [KVKey] {
        let base = activePrefix.isEmpty ? firstPage.value?.keys ?? [] : prefixPage?.keys ?? []
        return base + additionalKeys
    }

    var body: some View {
        List {
            RefreshErrorSection(resource: firstPage)
            Section {
                ForEach(keys) { key in
                    NavigationLink(value: StorageDestination.kvValue(namespaceId: namespaceId, key: key)) {
                        KVKeyRow(key: key)
                    }
                }
                if nextCursor != nil {
                    LoadMoreButton(isLoading: isLoadingMore) { await loadMore() }
                }
            } footer: {
                if let loadError {
                    Text(loadError)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(.storageKvSearchKeys))
        .onSubmit(of: .search) {
            Task { await search(prefix: searchText) }
        }
        .onChange(of: searchText) { _, newValue in
            if newValue.isEmpty && !activePrefix.isEmpty {
                Task { await search(prefix: "") }
            }
        }
        .resourceStatus(firstPage, emptyTitle: .storageKvKeysEmpty, emptySystemImage: "key") { page in
            page.keys.isEmpty && activePrefix.isEmpty
        }
        .overlay {
            if !activePrefix.isEmpty, prefixPage?.keys.isEmpty == true {
                ContentUnavailableView.search(text: activePrefix)
            }
        }
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func reload() async {
        if activePrefix.isEmpty {
            await firstPage.refresh {
                try await client.kvKeys(accountId: accountId, namespaceId: namespaceId)
            }
            additionalKeys = []
            nextCursor = firstPage.value?.nextCursor
        } else {
            await search(prefix: activePrefix)
        }
    }

    private func search(prefix: String) async {
        activePrefix = prefix
        additionalKeys = []
        loadError = nil
        guard !prefix.isEmpty else {
            prefixPage = nil
            nextCursor = firstPage.value?.nextCursor
            return
        }
        do {
            let page = try await client.kvKeys(accountId: accountId, namespaceId: namespaceId, prefix: prefix)
            prefixPage = page
            nextCursor = page.nextCursor
        } catch {
            prefixPage = KVKeyPage(keys: [], nextCursor: nil)
            nextCursor = nil
            loadError = error.localizedDescription
        }
    }

    private func loadMore() async {
        guard let cursor = nextCursor else { return }
        isLoadingMore = true
        loadError = nil
        defer { isLoadingMore = false }
        do {
            let page = try await client.kvKeys(
                accountId: accountId,
                namespaceId: namespaceId,
                prefix: activePrefix,
                cursor: cursor
            )
            additionalKeys += page.keys
            nextCursor = page.nextCursor
        } catch {
            loadError = error.localizedDescription
        }
    }
}
