import CloudflareKit
import SwiftUI

struct ZonesListView: View {
    let client: CloudflareClient
    let accountId: String

    @State private var zones: CachedResource<[Zone]>
    @State private var searchText = ""
    @State private var path: [Zone] = []
    private let navigator = AppNavigator.shared

    init(client: CloudflareClient, accountId: String) {
        self.client = client
        self.accountId = accountId
        _zones = State(initialValue: CachedResource(key: "zones-\(accountId)"))
    }

    private var filteredZones: [Zone] {
        let all = (zones.value ?? []).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                RefreshErrorSection(resource: zones)
                ForEach(filteredZones) { zone in
                    NavigationLink(value: zone) {
                        ZoneRow(zone: zone)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle(.tabsDomains)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(.domainsSearch))
            .resourceStatus(
                zones,
                emptyTitle: .domainsEmptyTitle,
                emptySystemImage: "globe",
                emptyDescription: .domainsEmptyMessage
            )
            .navigationDestination(for: Zone.self) { zone in
                ZoneDetailView(client: client, accountId: accountId, zone: zone) { updated in
                    zones.update { list in
                        if let index = list.firstIndex(where: { $0.id == updated.id }) {
                            list[index] = updated
                        }
                    }
                }
            }
            .onChange(of: navigator.pendingRequest, initial: true) { _, request in
                guard let request, request.accountId == accountId,
                      case .zone(let zone) = request.destination else { return }
                path = [zone]
                navigator.pendingRequest = nil
            }
            .task { await reload() }
            .refreshable { await reload() }
        }
    }

    private func reload() async {
        await zones.refresh {
            try await client.zones(accountId: accountId)
        }
    }
}
