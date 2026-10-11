import AppIntents
import CloudflareKit

struct WorkerEntityQuery: EntityStringQuery {
    func entities(for identifiers: [WorkerEntity.ID]) async throws -> [WorkerEntity] {
        let available = try await suggestedEntities()
        return available.filter { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [WorkerEntity] {
        try await suggestedEntities().filter { $0.name.localizedCaseInsensitiveContains(string) }
    }

    func suggestedEntities() async throws -> [WorkerEntity] {
        var entities: [WorkerEntity] = []
        for accountID in SharedAccountStore.accountIDs {
            let cached = SharedAccountStore.value(key: "Workers.\(accountID)", as: [WorkerEntity].self) ?? []
            do {
                let client = try IntentContext.client(accountId: accountID)
                let fetched = try await client.workerScripts(accountId: accountID).map { WorkerEntity(accountId: accountID, name: $0.name) }
                SharedAccountStore.store(fetched, key: "Workers.\(accountID)")
                entities += fetched
            } catch {
                guard !cached.isEmpty else { throw error }
                entities += cached
            }
        }
        return entities.sorted { $0.name < $1.name }
    }
}
