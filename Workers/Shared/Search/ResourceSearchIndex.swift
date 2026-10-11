import AppIntents
import CoreSpotlight

enum ResourceSearchIndex {
    private static var pendingUpdate: Task<Void, Never>?

    static func rebuild() async {
        let previousUpdate = pendingUpdate
        let update = Task {
            await previousUpdate?.value
            let index = CSSearchableIndex.default()
            let workers = SharedAccountStore.accountIDs.flatMap {
                SharedAccountStore.value(key: "Workers.\($0)", as: [WorkerEntity].self) ?? []
            }
            let zones = SharedAccountStore.accountIDs.flatMap {
                SharedAccountStore.value(key: "Zones.\($0)", as: [ZoneEntity].self) ?? []
            }
            do {
                try await index.deleteAppEntities(ofType: WorkerEntity.self)
                try await index.deleteAppEntities(ofType: ZoneEntity.self)
                try await index.indexAppEntities(workers)
                try await index.indexAppEntities(zones)
            } catch {
                return
            }
        }
        pendingUpdate = update
        await update.value
    }
}
