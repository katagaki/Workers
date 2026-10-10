import Foundation

public extension CloudflareClient {
    func zones(accountId: String? = nil) async throws -> [Zone] {
        var query: [URLQueryItem] = []
        if let accountId {
            query.append(URLQueryItem(name: "account.id", value: accountId))
        }
        return try await allPages(path: "zones", query: query)
    }

    func zone(id zoneId: String) async throws -> Zone {
        try await result(path: "zones/\(zoneId)")
    }

    func setZonePaused(zoneId: String, paused: Bool) async throws -> Zone {
        try await result(.patch, path: "zones/\(zoneId)", body: try encode(["paused": paused]))
    }

    func purgeEverything(zoneId: String) async throws {
        let _: APIEnvelope<JSONValue> = try await send(
            .post,
            path: "zones/\(zoneId)/purge_cache",
            body: try encode(["purge_everything": true])
        )
    }

    func dnsRecords(zoneId: String) async throws -> [DNSRecord] {
        try await allPages(path: "zones/\(zoneId)/dns_records", perPage: 100)
    }

    func createDNSRecord(zoneId: String, record: DNSRecordInput) async throws -> DNSRecord {
        try await result(.post, path: "zones/\(zoneId)/dns_records", body: try encode(record))
    }

    func updateDNSRecord(zoneId: String, recordId: String, record: DNSRecordInput) async throws -> DNSRecord {
        try await result(.put, path: "zones/\(zoneId)/dns_records/\(recordId)", body: try encode(record))
    }

    func deleteDNSRecord(zoneId: String, recordId: String) async throws {
        let _: APIEnvelope<JSONValue> = try await send(.delete, path: "zones/\(zoneId)/dns_records/\(recordId)")
    }
}
