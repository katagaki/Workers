import Foundation

public extension CloudflareClient {
    func r2Buckets(accountId: String) async throws -> [R2Bucket] {
        var buckets: [R2Bucket] = []
        var cursor: String?
        repeat {
            var query = [URLQueryItem(name: "per_page", value: "1000")]
            if let cursor {
                query.append(URLQueryItem(name: "cursor", value: cursor))
            }
            let envelope: APIEnvelope<R2BucketList> = try await send(path: "accounts/\(accountId)/r2/buckets", query: query)
            let page = envelope.result?.buckets ?? []
            buckets += page
            cursor = page.isEmpty ? nil : envelope.resultInfo?.cursor.flatMap { $0.isEmpty ? nil : $0 }
        } while cursor != nil
        return buckets
    }

    func r2Objects(
        accountId: String,
        bucketName: String,
        prefix: String = "",
        cursor: String? = nil,
        limit: Int = 100
    ) async throws -> R2ObjectPage {
        var query = [
            URLQueryItem(name: "delimiter", value: "/"),
            URLQueryItem(name: "per_page", value: String(limit))
        ]
        if !prefix.isEmpty {
            query.append(URLQueryItem(name: "prefix", value: prefix))
        }
        if let cursor {
            query.append(URLQueryItem(name: "cursor", value: cursor))
        }
        let envelope: APIEnvelope<[R2Object]> = try await send(
            path: "accounts/\(accountId)/r2/buckets/\(bucketName)/objects",
            query: query
        )
        let info = envelope.resultInfo
        let nextCursor = info?.isTruncated == true ? info?.cursor.flatMap { $0.isEmpty ? nil : $0 } : nil
        return R2ObjectPage(objects: envelope.result ?? [], folders: info?.delimited ?? [], nextCursor: nextCursor)
    }

    func r2ObjectData(accountId: String, bucketName: String, key: String) async throws -> Data {
        try await rawData(path: "accounts/\(accountId)/r2/buckets/\(bucketName)/objects", pathComponent: key)
    }
}
