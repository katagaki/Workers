import CloudflareKit
import SwiftUI

struct ZonesListView: View {
    let client: CloudflareClient
    let accountId: String

    @State private var zones: CachedResource<[Zone]>
    @State private var searchText = ""

    init(client: CloudflareClient, accountId: String) {
        self.client = client
        self.accountId = accountId
        _zones = State(initialValue: CachedResource(key: "zones-\(accountId)"))
    }

    private var filteredZones: [Zone] {
        let all = (zones.value ?? []).sorted { $0.name < $1.name }
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
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
