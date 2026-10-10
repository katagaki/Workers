import Foundation

public extension CloudflareClient {
    func kvNamespaces(accountId: String) async throws -> [KVNamespace] {
        try await allPages(path: "accounts/\(accountId)/storage/kv/namespaces", perPage: 100)
    }

    func kvKeys(
        accountId: String,
        namespaceId: String,
        prefix: String? = nil,
        cursor: String? = nil,
        limit: Int = 100
    ) async throws -> KVKeyPage {
        var query = [URLQueryItem(name: "limit", value: String(limit))]
        if let prefix, !prefix.isEmpty {
            query.append(URLQueryItem(name: "prefix", value: prefix))
        }
        if let cursor {
            query.append(URLQueryItem(name: "cursor", value: cursor))
        }
        let envelope: APIEnvelope<[KVKey]> = try await send(
            path: "accounts/\(accountId)/storage/kv/namespaces/\(namespaceId)/keys",
            query: query
        )
        let nextCursor = envelope.resultInfo?.cursor
        return KVKeyPage(keys: envelope.result ?? [], nextCursor: (nextCursor?.isEmpty ?? true) ? nil : nextCursor)
    }

    func kvValue(accountId: String, namespaceId: String, key: String) async throws -> Data {
        try await rawData(path: "accounts/\(accountId)/storage/kv/namespaces/\(namespaceId)/values", pathComponent: key)
    }
}
