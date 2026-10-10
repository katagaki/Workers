import AppIntents
import CloudflareKit

struct WorkerEntityQuery: EntityStringQuery {
    func entities(for identifiers: [WorkerEntity.ID]) async throws -> [WorkerEntity] {
        identifiers.compactMap(WorkerEntity.init(id:))
    }

    func entities(matching string: String) async throws -> [WorkerEntity] {
        try await suggestedEntities().filter { $0.name.localizedCaseInsensitiveContains(string) }
    }

    func suggestedEntities() async throws -> [WorkerEntity] {
        let client = try IntentContext.client()
        let accountId = try await IntentContext.selectedAccountId(client: client)
        return try await client.workerScripts(accountId: accountId)
            .map { WorkerEntity(accountId: accountId, name: $0.name) }
            .sorted { $0.name < $1.name }
    }
}
