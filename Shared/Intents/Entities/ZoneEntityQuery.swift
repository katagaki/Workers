import AppIntents
import CloudflareKit

struct ZoneEntityQuery: EntityStringQuery {
    func entities(for identifiers: [ZoneEntity.ID]) async throws -> [ZoneEntity] {
        try await suggestedEntities().filter { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [ZoneEntity] {
        try await suggestedEntities().filter { $0.name.localizedCaseInsensitiveContains(string) }
    }

    func suggestedEntities() async throws -> [ZoneEntity] {
        var entities: [ZoneEntity] = []
        for accountID in SharedAccountStore.accountIDs {
            let cached = SharedAccountStore.value(key: "Zones.\(accountID)", as: [ZoneEntity].self) ?? []
            do {
                let client = try IntentContext.client(accountId: accountID)
                let fetched = try await client.zones(accountId: accountID).map(ZoneEntity.init(zone:))
                SharedAccountStore.store(fetched, key: "Zones.\(accountID)")
                entities += fetched
            } catch {
                guard !cached.isEmpty else { throw error }
                entities += cached
            }
        }
        return entities.sorted { $0.name < $1.name }
    }
}
