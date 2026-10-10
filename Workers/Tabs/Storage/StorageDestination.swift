import CloudflareKit
import SwiftUI

enum StorageDestination: Hashable {
    case d1Database(databaseId: String, name: String, database: D1Database?)
    case d1Query(databaseId: String)
    case d1Table(databaseId: String, table: String)
    case d1Row(columns: [String], row: [JSONValue], index: Int)
    case durableObjectNamespace(DurableObjectNamespace)
    case kvNamespace(namespaceId: String, title: String)
    case kvValue(namespaceId: String, key: KVKey)
    case r2Bucket(bucketName: String, prefix: String)
    case r2Object(bucketName: String, object: R2Object)

    @ViewBuilder
    func view(client: CloudflareClient, accountId: String) -> some View {
        switch self {
        case .d1Database(let databaseId, let name, let database):
            D1DatabaseView(client: client, accountId: accountId, databaseId: databaseId, name: name, database: database)
        case .d1Query(let databaseId):
            D1QueryView(client: client, accountId: accountId, databaseId: databaseId)
        case .d1Table(let databaseId, let table):
            D1TableView(client: client, accountId: accountId, databaseId: databaseId, table: table)
        case .d1Row(let columns, let row, let index):
            D1RowView(columns: columns, row: row, index: index)
        case .durableObjectNamespace(let namespace):
            NamespaceDetailView(client: client, accountId: accountId, namespace: namespace)
        case .kvNamespace(let namespaceId, let title):
            KVNamespaceView(client: client, accountId: accountId, namespaceId: namespaceId, title: title)
        case .kvValue(let namespaceId, let key):
            KVValueView(client: client, accountId: accountId, namespaceId: namespaceId, key: key)
        case .r2Bucket(let bucketName, let prefix):
            R2BucketView(client: client, accountId: accountId, bucketName: bucketName, prefix: prefix)
        case .r2Object(let bucketName, let object):
            R2ObjectView(client: client, accountId: accountId, bucketName: bucketName, object: object)
        }
    }
}
