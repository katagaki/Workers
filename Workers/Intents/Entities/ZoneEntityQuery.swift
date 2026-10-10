import AppIntents
import CloudflareKit

struct ZoneEntityQuery: EntityStringQuery {
    func entities(for identifiers: [ZoneEntity.ID]) async throws -> [ZoneEntity] {
        let client = try IntentContext.client()
        var entities: [ZoneEntity] = []
        for identifier in identifiers {
            if let zone = try? await client.zone(id: identifier) {
                entities.append(ZoneEntity(zone: zone))
            }
        }
        return entities
    }

    func entities(matching string: String) async throws -> [ZoneEntity] {
        try await suggestedEntities().filter { $0.name.localizedCaseInsensitiveContains(string) }
    }

    func suggestedEntities() async throws -> [ZoneEntity] {
        let client = try IntentContext.client()
        let accountId = try await IntentContext.selectedAccountId(client: client)
        return try await client.zones(accountId: accountId)
            .map(ZoneEntity.init(zone:))
            .sorted { $0.name < $1.name }
    }
}
