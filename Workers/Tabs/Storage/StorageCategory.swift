import SwiftUI

enum StorageCategory: String, CaseIterable, Hashable {
    case d1
    case durableObjects
    case kv
    case r2

    var title: LocalizedStringResource {
        switch self {
        case .d1: .storageD1Title
        case .durableObjects: .tabsDurableObjects
        case .kv: .storageKvTitle
        case .r2: .storageR2Title
        }
    }

    var systemImage: String {
        switch self {
        case .d1: "cylinder.fill"
        case .durableObjects: "shippingbox.fill"
        case .kv: "key.fill"
        case .r2: "archivebox.fill"
        }
    }

    var color: Color {
        switch self {
        case .d1: .green
        case .durableObjects: .orange
        case .kv: .blue
        case .r2: .purple
        }
    }

    @ViewBuilder
    func view(resources: AccountResources) -> some View {
        switch self {
        case .d1:
            D1DatabasesListView(client: resources.client, accountId: resources.accountId, databases: resources.databases)
        case .durableObjects:
            NamespacesListView(client: resources.client, accountId: resources.accountId)
        case .kv:
            KVNamespacesListView(client: resources.client, accountId: resources.accountId, namespaces: resources.kvNamespaces)
        case .r2:
            R2BucketsListView(client: resources.client, accountId: resources.accountId, buckets: resources.buckets)
        }
    }
}
