import AppIntents
import CloudflareKit

struct WorkerEntityQuery: EntityStringQuery {
    func entities(for identifiers: [WorkerEntity.ID]) async throws -> [WorkerEntity] {
        let cached = SharedAccountStore.accountIDs.flatMap {
            SharedAccountStore.value(key: "Workers.\($0)", as: [WorkerEntity].self) ?? []
        }.filter { identifiers.contains($0.id) }
        if Set(cached.map(\.id)) == Set(identifiers) { return cached }
        return try await suggestedEntities().filter { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [WorkerEntity] {
        try await suggestedEntities().filter { $0.name.localizedCaseInsensitiveContains(string) }
    }

    func suggestedEntities() async throws -> [WorkerEntity] {
        var entities: [WorkerEntity] = []
        var firstError: Error?
        for accountID in SharedAccountStore.accountIDs {
            let cached = SharedAccountStore.value(key: "Workers.\(accountID)", as: [WorkerEntity].self) ?? []
            do {
                let client = try IntentContext.client(accountId: accountID)
                let fetched = try await client.workerScripts(accountId: accountID).map { WorkerEntity(accountId: accountID, name: $0.name) }
                SharedAccountStore.store(fetched, key: "Workers.\(accountID)")
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
