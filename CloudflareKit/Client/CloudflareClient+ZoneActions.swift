import Foundation

public extension CloudflareClient {
    func zoneSecurityLevel(zoneId: String) async throws -> ZoneSecurityLevel {
        try await result(path: "zones/\(zoneId)/settings/security_level")
    }

    func setZoneUnderAttack(zoneId: String, enabled: Bool, restoredLevel: String = "medium") async throws -> ZoneSecurityLevel {
        try await result(.patch, path: "zones/\(zoneId)/settings/security_level", body: try encode(["value": enabled ? "under_attack" : restoredLevel]))
    }

    func purgeURLs(zoneId: String, urls: [URL]) async throws {
        guard !urls.isEmpty, urls.count <= 100,
              urls.allSatisfy({ ["http", "https"].contains($0.scheme?.lowercased() ?? "") && $0.host != nil }) else {
            throw CloudflareError.invalidResponse
        }
        let _: APIEnvelope<JSONValue> = try await send(.post, path: "zones/\(zoneId)/purge_cache", body: try encode(["files": urls.map(\.absoluteString)]))
    }
}
