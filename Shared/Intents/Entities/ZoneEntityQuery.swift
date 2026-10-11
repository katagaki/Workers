import AppIntents
import CloudflareKit

struct ZoneEntityQuery: EntityStringQuery {
    func entities(for identifiers: [ZoneEntity.ID]) async throws -> [ZoneEntity] {
        let cached = SharedAccountStore.accountIDs.flatMap {
            SharedAccountStore.value(key: "Zones.\($0)", as: [ZoneEntity].self) ?? []
        }.filter { identifiers.contains($0.id) }
        if Set(cached.map(\.id)) == Set(identifiers) { return cached }
        return try await suggestedEntities().filter { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [ZoneEntity] {
        try await suggestedEntities().filter { $0.name.localizedCaseInsensitiveContains(string) }
    }

    func suggestedEntities() async throws -> [ZoneEntity] {
        var entities: [ZoneEntity] = []
        var firstError: Error?
        for accountID in SharedAccountStore.accountIDs {
            let cached = SharedAccountStore.value(key: "Zones.\(accountID)", as: [ZoneEntity].self) ?? []
            do {
                let client = try IntentContext.client(accountId: accountID)
                let fetched = try await client.zones(accountId: accountID).map(ZoneEntity.init(zone:))
                SharedAccountStore.store(fetched, key: "Zones.\(accountID)")
                entities += fetched
            } catch {
                if firstError == nil { firstError = error }
                entities += cached
            }
        }
        if entities.isEmpty, let firstError { throw firstError }
        return entities.sorted { $0.name < $1.name }
    }
}
