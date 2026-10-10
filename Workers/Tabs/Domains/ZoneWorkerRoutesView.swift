import CloudflareKit
import SwiftUI

struct ZoneWorkerRoutesView: View {
    let client: CloudflareClient
    let zoneId: String

    @State private var routes: CachedResource<[WorkerRoute]>

    init(client: CloudflareClient, zoneId: String) {
        self.client = client
        self.zoneId = zoneId
        _routes = State(initialValue: CachedResource(key: "zone-routes-\(zoneId)"))
    }

    var body: some View {
        List {
            RefreshErrorSection(resource: routes)
            ForEach(routes.value ?? []) { route in
                VStack(alignment: .leading, spacing: 3) {
                    Text(route.pattern)
                        .font(.body.weight(.medium))
                    Text(route.script ?? String(localized: .domainsRoutesNoWorker))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(.domainsRoutesTitle)
        .resourceStatus(routes, emptyTitle: .domainsRoutesEmpty, emptySystemImage: "arrow.triangle.branch")
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func reload() async {
        await routes.refresh {
            try await client.workerRoutes(zoneId: zoneId)
        }
    }
}
