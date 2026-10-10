import CloudflareKit
import SwiftUI

extension MainTabView {
    @TabContentBuilder<AppTab>
    var workersSection: some TabContent<AppTab> {
        TabSection(.tabsWorkers) {
            ForEach(resources?.sortedScripts ?? []) { script in
                Tab(script.name, systemImage: "hammer", value: AppTab.worker(name: script.name)) {
                    accountScoped { resources in
                        NavigationStack {
                            WorkerDetailView(client: resources.client, accountId: resources.accountId, script: script) {
                                resources.removeScript(script)
                                selectedTab = .workers
                            }
                            .navigationBarTitleDisplayMode(.large)
                            .navigationDestination(for: WorkersDestination.self) { destination in
                                destination.view(client: resources.client, accountId: resources.accountId)
                            }
                            .navigationDestination(for: StorageDestination.self) { destination in
                                destination.view(client: resources.client, accountId: resources.accountId)
                            }
                        }
                    }
                }
                .defaultVisibility(.hidden, for: .tabBar)
            }
        }
    }

    @TabContentBuilder<AppTab>
    var storageSection: some TabContent<AppTab> {
        TabSection(.tabsStorage) {
            ForEach(StorageCategory.allCases, id: \.self) { category in
                Tab(value: AppTab.storageCategory(category)) {
                    accountScoped { resources in
                        NavigationStack {
                            category.view(resources: resources)
                                .navigationBarTitleDisplayMode(.large)
                                .navigationDestination(for: StorageDestination.self) { destination in
                                    destination.view(client: resources.client, accountId: resources.accountId)
                                }
                        }
                    }
                } label: {
                    Label(category.title, systemImage: category.systemImage)
                }
                .badge(resources?.count(of: category) ?? 0)
                .defaultVisibility(.hidden, for: .tabBar)
            }
        }
    }

    @TabContentBuilder<AppTab>
    var domainsSection: some TabContent<AppTab> {
        TabSection(.tabsDomains) {
            ForEach(resources?.sortedZones ?? []) { zone in
                Tab(zone.name, systemImage: "globe", value: AppTab.zone(id: zone.id)) {
                    accountScoped { resources in
                        NavigationStack {
                            ZoneDetailView(client: resources.client, accountId: resources.accountId, zone: zone) { updated in
                                resources.replaceZone(updated)
                            }
                            .navigationBarTitleDisplayMode(.large)
                            .navigationDestination(for: DomainsDestination.self) { destination in
                                destination.view(client: resources.client)
                            }
                        }
                    }
                }
                .defaultVisibility(.hidden, for: .tabBar)
            }
        }
    }
}
