import CloudflareKit
import Observation
import WidgetKit

@Observable
final class AccountResources {
    let client: CloudflareClient
    let accountId: String

    let scripts: CachedResource<[WorkerScript]>
    let workerAnalytics: CachedResource<[WorkerAnalyticsPoint]>
    let zones: CachedResource<[Zone]>
    let databases: CachedResource<[D1Database]>
    let durableObjectNamespaces: CachedResource<[DurableObjectNamespace]>
    let kvNamespaces: CachedResource<[KVNamespace]>
    let buckets: CachedResource<[R2Bucket]>

    init(client: CloudflareClient, accountId: String) {
        self.client = client
        self.accountId = accountId
        scripts = CachedResource(key: "workers-\(accountId)")
        workerAnalytics = CachedResource(key: "workers-analytics-\(accountId)-day")
        zones = CachedResource(key: "zones-\(accountId)")
        databases = CachedResource(key: "d1-databases-\(accountId)")
        durableObjectNamespaces = CachedResource(key: "do-namespaces-\(accountId)")
        kvNamespaces = CachedResource(key: "kv-namespaces-\(accountId)")
        buckets = CachedResource(key: "r2-buckets-\(accountId)")
    }

    var sortedScripts: [WorkerScript] {
        (scripts.value ?? []).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var sortedZones: [Zone] {
        (zones.value ?? []).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func count(of category: StorageCategory) -> Int? {
        switch category {
        case .d1: databases.value?.count
        case .durableObjects: durableObjectNamespaces.value?.count
        case .kv: kvNamespaces.value?.count
        case .r2: buckets.value?.count
        }
    }

    func reloadAll() async {
        async let workersLoad: Void = reloadWorkers()
        async let zonesLoad: Void = reloadZones()
        async let storageLoad: Void = reloadStorage()
        _ = await (workersLoad, zonesLoad, storageLoad)
    }

    func reloadWorkers() async {
        async let scriptsLoad: Void = scripts.refresh {
            try await client.workerScripts(accountId: accountId)
        }
        async let analyticsLoad: Void = workerAnalytics.refresh {
            try await client.workerAnalytics(accountId: accountId, range: .day)
        }
        _ = await (scriptsLoad, analyticsLoad)
        if let scripts = scripts.value {
            SharedAccountStore.store(scripts.map { WorkerEntity(accountId: accountId, name: $0.name) }, key: "Workers.\(accountId)")
            if let points = workerAnalytics.value {
                for script in scripts {
                    let snapshot = WorkerWidgetSnapshot(worker: WorkerEntity(accountId: accountId, name: script.name), analytics: points.filter { $0.scriptName == script.name })
                    SharedAccountStore.store(snapshot, key: snapshot.cacheKey)
                }
                WidgetCenter.shared.reloadAllTimelines()
            }
            await ResourceSearchIndex.rebuild()
        }
    }

    func reloadZones() async {
        await zones.refresh {
            try await client.zones(accountId: accountId)
        }
        if let zones = zones.value {
            SharedAccountStore.store(zones.map(ZoneEntity.init(zone:)), key: "Zones.\(accountId)")
            await ResourceSearchIndex.rebuild()
        }
    }

    func reloadStorage() async {
        async let durableObjectsLoad: Void = durableObjectNamespaces.refresh {
            try await client.durableObjectNamespaces(accountId: accountId)
        }
        async let kvLoad: Void = kvNamespaces.refresh {
            try await client.kvNamespaces(accountId: accountId)
        }
        async let r2Load: Void = buckets.refresh {
            try await client.r2Buckets(accountId: accountId)
        }
        async let d1Load: Void = databases.refresh {
            try await client.d1Databases(accountId: accountId)
        }
        _ = await (durableObjectsLoad, kvLoad, r2Load, d1Load)
    }

    func removeScript(_ script: WorkerScript) {
        scripts.update { $0.removeAll { $0.id == script.id } }
        SharedAccountStore.store((scripts.value ?? []).map { WorkerEntity(accountId: accountId, name: $0.name) }, key: "Workers.\(accountId)")
        Task { await ResourceSearchIndex.rebuild() }
    }

    func replaceZone(_ zone: Zone) {
        zones.update { list in
            if let index = list.firstIndex(where: { $0.id == zone.id }) {
                list[index] = zone
            }
        }
    }
}
