import CloudflareKit
import SwiftUI

struct WorkerTriggersView: View {
    let client: CloudflareClient
    let accountId: String
    let scriptName: String

    @State private var triggers: CachedResource<WorkerTriggers>

    init(client: CloudflareClient, accountId: String, scriptName: String) {
        self.client = client
        self.accountId = accountId
        self.scriptName = scriptName
        _triggers = State(initialValue: CachedResource(key: "worker-triggers-\(accountId)-\(scriptName)"))
    }

    var body: some View {
        List {
            RefreshErrorSection(resource: triggers)
            if let value = triggers.value {
                if !value.customDomains.isEmpty {
                    Section(.workersTriggersCustomDomains) {
                        ForEach(value.customDomains) { domain in
                            if let url = URL(string: "https://\(domain.hostname)") {
                                Link(destination: url) {
                                    Label(domain.hostname, systemImage: "globe")
                                }
                            }
                        }
                    }
                }
                if !value.routes.isEmpty {
                    Section(.workersTriggersRoutes) {
                        ForEach(value.routes) { route in
                            Label(route.pattern, systemImage: "arrow.triangle.branch")
                        }
                    }
                }
                if !value.schedules.isEmpty {
                    Section(.workersTriggersCronTriggers) {
                        ForEach(value.schedules) { schedule in
                            VStack(alignment: .leading, spacing: 3) {
                                Label(schedule.cron, systemImage: "clock")
                                if let description = CronDescription(schedule.cron).text {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(.workersTriggersTitle)
        .resourceStatus(
            triggers,
            emptyTitle: .workersTriggersEmptyTitle,
            emptySystemImage: "bolt",
            emptyDescription: .workersTriggersEmptyMessage,
            isEmpty: \.isEmpty
        )
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func reload() async {
        await triggers.refresh {
            async let schedules = client.workerSchedules(accountId: accountId, scriptName: scriptName)
            async let domains = client.workerCustomDomains(accountId: accountId)
            async let routes = routesForScript()
            return try await WorkerTriggers(
                customDomains: domains.filter { $0.service == scriptName },
                routes: routes,
                schedules: schedules
            )
        }
    }

    private func routesForScript() async throws -> [WorkerRoute] {
        let zones = try await client.zones(accountId: accountId)
        return try await withThrowingTaskGroup(of: [WorkerRoute].self) { group in
            for zone in zones {
                group.addTask {
                    (try? await client.workerRoutes(zoneId: zone.id)) ?? []
                }
            }
            var routes: [WorkerRoute] = []
            for try await zoneRoutes in group {
                routes += zoneRoutes.filter { $0.script == scriptName }
            }
            return routes.sorted { $0.pattern < $1.pattern }
        }
    }
}
