import CloudflareKit
import SwiftUI

struct D1DatabasesListView: View {
    let client: CloudflareClient
    let accountId: String
    let databases: CachedResource<[D1Database]>

    @State private var searchText = ""

    private var filteredDatabases: [D1Database] {
        let all = (databases.value ?? []).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            RefreshErrorSection(resource: databases)
            ForEach(filteredDatabases) { database in
                NavigationLink(value: StorageDestination.d1Database(databaseId: database.uuid, name: database.name, database: database)) {
                    LabeledContent {
                        if let fileSize = database.fileSize {
                            Text(fileSize.byteFormatted)
                        }
                    } label: {
                        Text(database.name)
                            .lineLimit(1)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(.storageD1Title)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(.storageD1Search))
        .resourceStatus(
            databases,
            emptyTitle: .storageD1EmptyTitle,
            emptySystemImage: "cylinder",
            emptyDescription: .storageD1EmptyMessage
        )
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func reload() async {
        await databases.refresh {
            try await client.d1Databases(accountId: accountId)
        }
    }
}
