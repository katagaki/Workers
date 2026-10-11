import Foundation

public extension CloudflareClient {
    func deployWorkerVersions(
        accountId: String,
        scriptName: String,
        versions: [WorkerDeploymentInput.Version]
    ) async throws -> WorkerDeployment {
        guard !versions.isEmpty, versions.count <= 2,
              Set(versions.map(\.versionId)).count == versions.count,
              versions.allSatisfy({ !$0.versionId.isEmpty && $0.percentage.isFinite && $0.percentage > 0 && $0.percentage <= 100 }),
              abs(versions.reduce(0) { $0 + $1.percentage } - 100) < 0.001 else {
            throw CloudflareError.invalidResponse
        }
        return try await result(
            .post,
            path: "accounts/\(accountId)/workers/scripts/\(scriptName)/deployments",
            body: try encode(WorkerDeploymentInput(versions: versions))
        )
    }
}
