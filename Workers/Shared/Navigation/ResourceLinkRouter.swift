import CloudflareKit
import CoreSpotlight
import Foundation

nonisolated enum ResourceLinkRouter {
    static func worker(from url: URL) -> WorkerEntity? {
        guard url.scheme == "workers", url.host == "worker", let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let accountID = components.queryItems?.first(where: { $0.name == "account" })?.value,
              let name = components.queryItems?.first(where: { $0.name == "name" })?.value,
              !accountID.isEmpty, !name.isEmpty else { return nil }
        return WorkerEntity(accountId: accountID, name: name)
    }

    @MainActor static func open(worker: WorkerEntity) async throws {
        let client = try IntentContext.client(accountId: worker.accountId)
        guard let script = try await client.workerScripts(accountId: worker.accountId).first(where: { $0.name == worker.name }) else { throw IntentError.workerNotFound }
        AppNavigator.shared.open(.worker(script), accountId: worker.accountId)
    }

    @MainActor static func openSpotlight(identifier: String) async throws {
        for accountID in SharedAccountStore.accountIDs {
            let workers = SharedAccountStore.value(key: "Workers.\(accountID)", as: [WorkerEntity].self) ?? []
            if let worker = workers.first(where: { CSSearchableItem(appEntity: $0).uniqueIdentifier == identifier }) {
                try await open(worker: worker)
                return
            }
            let zones = SharedAccountStore.value(key: "Zones.\(accountID)", as: [ZoneEntity].self) ?? []
            if let entity = zones.first(where: { CSSearchableItem(appEntity: $0).uniqueIdentifier == identifier }) {
                let zone = try await IntentContext.client(zone: entity).zone(id: entity.id)
                AppNavigator.shared.open(.zone(zone), accountId: accountID)
                return
            }
        }
        throw IntentError.workerNotFound
    }
}
