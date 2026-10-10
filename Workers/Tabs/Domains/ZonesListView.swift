import CloudflareKit
import SwiftUI

struct ZonesListView: View {
    let resources: AccountResources

    @State private var searchText = ""
    @State private var path = NavigationPath()
    private let navigator = AppNavigator.shared

    private var filteredZones: [Zone] {
        guard !searchText.isEmpty else { return resources.sortedZones }
        return resources.sortedZones.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                RefreshErrorSection(resource: resources.zones)
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
                resources.zones,
                emptyTitle: .domainsEmptyTitle,
                emptySystemImage: "globe",
                emptyDescription: .domainsEmptyMessage
            )
            .navigationDestination(for: Zone.self) { zone in
                ZoneDetailView(client: resources.client, accountId: resources.accountId, zone: zone) { updated in
                    resources.replaceZone(updated)
                }
                .navigationBarTitleDisplayMode(.inline)
            }
            .navigationDestination(for: DomainsDestination.self) { destination in
                destination.view(client: resources.client)
            }
            .onChange(of: navigator.pendingRequest, initial: true) { _, request in
                guard let request, request.accountId == resources.accountId,
                      case .zone(let zone) = request.destination else { return }
                path = NavigationPath([zone])
                navigator.pendingRequest = nil
            }
            .task { await resources.reloadZones() }
            .refreshable { await resources.reloadZones() }
        }
    }
}
