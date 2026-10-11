import Foundation

final class DemoDeployments: @unchecked Sendable {
    static let shared = DemoDeployments()
    private let lock = NSLock()
    private var history: [String: [[String: Any]]] = [:]

    func response(method: String, script: DemoData.Script, body: [String: Any]?) -> [String: Any] {
        lock.withLock {
            var deployments = history[script.name] ?? DemoResources.deployments(for: script)
            if method == "POST" {
                let deployment: [String: Any] = [
                    "id": UUID().uuidString,
                    "created_on": Date.now.formatted(.iso8601),
                    "source": "api",
                    "strategy": "percentage",
                    "versions": body?["versions"] ?? [],
                    "annotations": ["workers/message": "Deployed from Workers for iOS"]
                ]
                deployments.insert(deployment, at: 0)
                history[script.name] = deployments
                return DemoRouter.envelope(deployment)
            }
            return DemoRouter.envelope(["deployments": deployments])
        }
    }
}
