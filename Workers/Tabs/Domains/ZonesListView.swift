import CloudflareKit
import SwiftUI

struct ZonesListView: View {
    let client: CloudflareClient
    let accountId: String

    @State private var zones: CachedResource<[Zone]>
    @State private var searchText = ""
    @State private var selection: Zone?
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
        NavigationSplitView {
            List(selection: $selection) {
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
            .onChange(of: navigator.pendingRequest, initial: true) { _, request in
                guard let request, request.accountId == accountId,
                      case .zone(let zone) = request.destination else { return }
                selection = zone
                navigator.pendingRequest = nil
            }
            .task { await reload() }
            .refreshable { await reload() }
        } detail: {
            if let selection {
                NavigationStack {
                    ZoneDetailView(client: client, accountId: accountId, zone: selection) { updated in
                        zones.update { list in
                            if let index = list.firstIndex(where: { $0.id == updated.id }) {
                                list[index] = updated
                            }
                        }
                        if self.selection?.id == updated.id {
                            self.selection = updated
                        }
                    }
                }
                .id(selection.id)
            } else {
                ContentUnavailableView(.domainsNoSelection, systemImage: "globe")
            }
        }
    }

    private func reload() async {
        await zones.refresh {
            try await client.zones(accountId: accountId)
        }
    }
}
