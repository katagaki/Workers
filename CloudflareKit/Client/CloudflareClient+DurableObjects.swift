import Foundation

public extension CloudflareClient {
    func durableObjectNamespaces(accountId: String) async throws -> [DurableObjectNamespace] {
        try await allPages(path: "accounts/\(accountId)/workers/durable_objects/namespaces", perPage: 100)
    }

    func durableObjects(
        accountId: String,
        namespaceId: String,
        cursor: String? = nil,
        limit: Int = 100
    ) async throws -> DurableObjectPage {
        var query = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor {
            query.append(URLQueryItem(name: "cursor", value: cursor))
        }
        let envelope: APIEnvelope<[DurableObjectInstance]> = try await send(
            path: "accounts/\(accountId)/workers/durable_objects/namespaces/\(namespaceId)/objects",
            query: query
        )
        let nextCursor = envelope.resultInfo?.cursor
        return DurableObjectPage(
            objects: envelope.result ?? [],
            nextCursor: (nextCursor?.isEmpty ?? true) ? nil : nextCursor
        )
    }
}
