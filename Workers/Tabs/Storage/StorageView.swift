import CloudflareKit
import SwiftUI

struct StorageView: View {
    let client: CloudflareClient
    let accountId: String

    @State private var durableObjectNamespaces: CachedResource<[DurableObjectNamespace]>
    @State private var kvNamespaces: CachedResource<[KVNamespace]>
    @State private var buckets: CachedResource<[R2Bucket]>
    @State private var databases: CachedResource<[D1Database]>
    @State private var selection: StorageCategory?
    @State private var path: [StorageDestination] = []

    init(client: CloudflareClient, accountId: String) {
        self.client = client
        self.accountId = accountId
        _durableObjectNamespaces = State(initialValue: CachedResource(key: "do-namespaces-\(accountId)"))
        _kvNamespaces = State(initialValue: CachedResource(key: "kv-namespaces-\(accountId)"))
        _buckets = State(initialValue: CachedResource(key: "r2-buckets-\(accountId)"))
        _databases = State(initialValue: CachedResource(key: "d1-databases-\(accountId)"))
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NavigationLink(value: StorageCategory.d1) {
                    row(title: .storageD1Title, systemImage: "cylinder.fill", color: .green, count: databases.value?.count)
                }
                NavigationLink(value: StorageCategory.durableObjects) {
                    row(title: .tabsDurableObjects, systemImage: "shippingbox.fill", color: .orange, count: durableObjectNamespaces.value?.count)
                }
                NavigationLink(value: StorageCategory.kv) {
                    row(title: .storageKvTitle, systemImage: "key.fill", color: .blue, count: kvNamespaces.value?.count)
                }
                NavigationLink(value: StorageCategory.r2) {
                    row(title: .storageR2Title, systemImage: "archivebox.fill", color: .purple, count: buckets.value?.count)
                }
            }
            .navigationTitle(.tabsStorage)
            .task { await reload() }
            .refreshable { await reload() }
            .onChange(of: selection) {
                path = []
            }
        } detail: {
            if let selection {
                NavigationStack(path: $path) {
                    detail(for: selection)
                        .navigationDestination(for: StorageDestination.self) { destination in
                            destination.view(client: client, accountId: accountId)
                        }
                }
                .id(selection)
            } else {
                ContentUnavailableView(.storageNoSelection, systemImage: "externaldrive")
            }
        }
    }

    @ViewBuilder
    private func detail(for category: StorageCategory) -> some View {
        switch category {
        case .d1:
            D1DatabasesListView(client: client, accountId: accountId, databases: databases)
        case .durableObjects:
            NamespacesListView(client: client, accountId: accountId)
        case .kv:
            KVNamespacesListView(client: client, accountId: accountId, namespaces: kvNamespaces)
        case .r2:
            R2BucketsListView(client: client, accountId: accountId, buckets: buckets)
        }
    }

    private func row(title: LocalizedStringResource, systemImage: String, color: Color, count: Int?) -> some View {
        LabeledContent {
            if let count {
                Text(count, format: .number)
            }
        } label: {
            SettingsLabel(title: title, systemImage: systemImage, color: color)
        }
    }

    private func reload() async {
        async let durableObjectsLoad: Void = durableObjectNamespaces.refresh {
            try await client.durableObjectNamespaces(accountId: accountId)
        }
        async let kvLoad: Void = kvNamespaces.refresh {
            try await client.kvNamespaces(accountId: accountId)
        }
        async let r2Load: Void = buckets.refresh {
            try await client.r2Buckets(accountId: accountId)
        }
        async let d1Load: Void = databases.refresh {
            try await client.d1Databases(accountId: accountId)
        }
        _ = await (durableObjectsLoad, kvLoad, r2Load, d1Load)
    }
}
