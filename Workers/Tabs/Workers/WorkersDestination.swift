import CloudflareKit
import SwiftUI

enum WorkersDestination: Hashable {
    case logs(scriptName: String)
    case deployments(scriptName: String)
    case versions(scriptName: String)
    case bindings(scriptName: String)
    case triggers(scriptName: String)
    case tailEvent(TailEvent)
    case observabilityEvent(ObservabilityEvent)

    @ViewBuilder
    func view(client: CloudflareClient, accountId: String) -> some View {
        switch self {
        case .logs(let scriptName):
            WorkerLogsView(client: client, accountId: accountId, scriptName: scriptName)
        case .deployments(let scriptName):
            WorkerDeploymentsView(client: client, accountId: accountId, scriptName: scriptName)
        case .versions(let scriptName):
            WorkerVersionsView(client: client, accountId: accountId, scriptName: scriptName)
        case .bindings(let scriptName):
            WorkerBindingsView(client: client, accountId: accountId, scriptName: scriptName)
        case .triggers(let scriptName):
            WorkerTriggersView(client: client, accountId: accountId, scriptName: scriptName)
        case .tailEvent(let event):
            TailEventDetailView(event: event)
        case .observabilityEvent(let event):
            ObservabilityEventDetailView(event: event)
        }
    }
}
