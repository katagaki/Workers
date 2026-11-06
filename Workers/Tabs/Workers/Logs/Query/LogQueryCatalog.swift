import CloudflareKit
import Foundation
import Observation

@Observable
final class LogQueryCatalog {
    private let client: CloudflareClient
    private let accountId: String
    private let scriptName: String
    private let discoveredKeys: CachedResource<[LogQueryKey]>
    private var valueResources: [String: CachedResource<[LogQueryValue]>] = [:]

    init(client: CloudflareClient, accountId: String, scriptName: String) {
        self.client = client
        self.accountId = accountId
        self.scriptName = scriptName
        discoveredKeys = CachedResource(key: "log-query-keys-\(accountId)-\(scriptName)")
    }

    var keys: [LogQueryKey] {
        LogQueryKey.merged(with: discoveredKeys.value ?? [])
    }

    func values(for key: String) -> [LogQueryValue] {
        valueResources[key]?.value ?? []
    }

    func loadKeys() async {
        await discoveredKeys.refresh {
            try await client.workerLogKeys(
                accountId: accountId,
                scriptName: scriptName,
                from: .now.addingTimeInterval(-LogWindow.week.duration),
                to: .now
            )
        }
    }

    func loadValues(for key: String) async {
        guard let queryKey = keys.first(where: { $0.key == key }) else { return }
        let resource = valueResources[key] ?? CachedResource(key: "log-query-values-\(accountId)-\(scriptName)-\(key)")
        valueResources[key] = resource
        await resource.refresh {
            try await client.workerLogValues(
                accountId: accountId,
                scriptName: scriptName,
                key: queryKey,
                from: .now.addingTimeInterval(-LogWindow.week.duration),
                to: .now
            )
        }
    }
}
