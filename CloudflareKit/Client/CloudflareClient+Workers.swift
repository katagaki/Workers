import Foundation

public extension CloudflareClient {
    func workerScripts(accountId: String) async throws -> [WorkerScript] {
        try await result(path: "accounts/\(accountId)/workers/scripts")
    }

    func workerDeployments(accountId: String, scriptName: String) async throws -> [WorkerDeployment] {
        let list: WorkerDeploymentList = try await result(
            path: "accounts/\(accountId)/workers/scripts/\(scriptName)/deployments"
        )
        return list.deployments
    }

    func workerVersions(accountId: String, scriptName: String) async throws -> [WorkerVersion] {
        let list: WorkerVersionList = try await result(
            path: "accounts/\(accountId)/workers/scripts/\(scriptName)/versions"
        )
        return list.items
    }

    func workerSettings(accountId: String, scriptName: String) async throws -> WorkerSettings {
        try await result(path: "accounts/\(accountId)/workers/scripts/\(scriptName)/settings")
    }

    func workerSchedules(accountId: String, scriptName: String) async throws -> [WorkerSchedule] {
        let list: WorkerScheduleList = try await result(
            path: "accounts/\(accountId)/workers/scripts/\(scriptName)/schedules"
        )
        return list.schedules
    }

    func workersSubdomain(accountId: String) async throws -> WorkersSubdomain {
        try await result(path: "accounts/\(accountId)/workers/subdomain")
    }

    func workersDevURL(scriptName: String, subdomain: String) -> URL? {
        let domain = isDemo ? "workers.invalid" : "workers.dev"
        return URL(string: "https://\(scriptName).\(subdomain).\(domain)")
    }

    func workerSubdomainStatus(accountId: String, scriptName: String) async throws -> WorkerSubdomainStatus {
        try await result(path: "accounts/\(accountId)/workers/scripts/\(scriptName)/subdomain")
    }

    func workerCustomDomains(accountId: String) async throws -> [WorkerCustomDomain] {
        try await result(path: "accounts/\(accountId)/workers/domains")
    }

    func workerRoutes(zoneId: String) async throws -> [WorkerRoute] {
        try await result(path: "zones/\(zoneId)/workers/routes")
    }

    func deleteWorkerScript(accountId: String, scriptName: String) async throws {
        let _: APIEnvelope<JSONValue> = try await send(
            .delete,
            path: "accounts/\(accountId)/workers/scripts/\(scriptName)"
        )
    }
}
