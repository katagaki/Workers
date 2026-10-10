import CloudflareKit
import SwiftUI

struct StorageView: View {
    let client: CloudflareClient
    let accountId: String

    @State private var durableObjectNamespaces: CachedResource<[DurableObjectNamespace]>
    @State private var kvNamespaces: CachedResource<[KVNamespace]>
    @State private var buckets: CachedResource<[R2Bucket]>
    @State private var databases: CachedResource<[D1Database]>

    init(client: CloudflareClient, accountId: String) {
        self.client = client
        self.accountId = accountId
        _durableObjectNamespaces = State(initialValue: CachedResource(key: "do-namespaces-\(accountId)"))
        _kvNamespaces = State(initialValue: CachedResource(key: "kv-namespaces-\(accountId)"))
        _buckets = State(initialValue: CachedResource(key: "r2-buckets-\(accountId)"))
        _databases = State(initialValue: CachedResource(key: "d1-databases-\(accountId)"))
    }

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    NamespacesListView(client: client, accountId: accountId)
                } label: {
                    row(title: .tabsDurableObjects, systemImage: "shippingbox.fill", color: .orange, count: durableObjectNamespaces.value?.count)
                }
                NavigationLink {
                    KVNamespacesListView(client: client, accountId: accountId, namespaces: kvNamespaces)
                } label: {
                    row(title: .storageKvTitle, systemImage: "key.fill", color: .blue, count: kvNamespaces.value?.count)
                }
                NavigationLink {
                    R2BucketsListView(client: client, accountId: accountId, buckets: buckets)
                } label: {
                    row(title: .storageR2Title, systemImage: "archivebox.fill", color: .purple, count: buckets.value?.count)
                }
                NavigationLink {
                    D1DatabasesListView(client: client, accountId: accountId, databases: databases)
                } label: {
                    row(title: .storageD1Title, systemImage: "cylinder.fill", color: .green, count: databases.value?.count)
                }
            }
            .navigationTitle(.tabsStorage)
            .task { await reload() }
            .refreshable { await reload() }
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
