import Foundation

public extension CloudflareClient {
    func d1Databases(accountId: String) async throws -> [D1Database] {
        try await allPages(path: "accounts/\(accountId)/d1/database", perPage: 100)
    }

    func d1Query(accountId: String, databaseId: String, sql: String, parameters: [String] = []) async throws -> [D1QueryResult] {
        let body = try JSONSerialization.data(withJSONObject: ["sql": sql, "params": parameters])
        return try await result(.post, path: "accounts/\(accountId)/d1/database/\(databaseId)/raw", body: body)
    }

    func d1Tables(accountId: String, databaseId: String) async throws -> [String] {
        let results = try await d1Query(
            accountId: accountId,
            databaseId: databaseId,
            sql: "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_cf_%' ORDER BY name"
        )
        return (results.first?.rows ?? []).compactMap { $0.first?.stringValue }
    }

    func d1TablePreview(accountId: String, databaseId: String, table: String, limit: Int = 100) async throws -> D1QueryResult {
        let quotedTable = "\"" + table.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        let results = try await d1Query(
            accountId: accountId,
            databaseId: databaseId,
            sql: "SELECT * FROM \(quotedTable) LIMIT \(limit)"
        )
        guard let first = results.first else { throw CloudflareError.invalidResponse }
        return first
    }
}
