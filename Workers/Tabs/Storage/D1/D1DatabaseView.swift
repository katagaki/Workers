import CloudflareKit
import SwiftUI

struct D1DatabaseView: View {
    let client: CloudflareClient
    let accountId: String
    let databaseId: String
    let name: String
    var database: D1Database?

    @State private var tables: CachedResource<[String]>

    init(client: CloudflareClient, accountId: String, databaseId: String, name: String, database: D1Database? = nil) {
        self.client = client
        self.accountId = accountId
        self.databaseId = databaseId
        self.name = name
        self.database = database
        _tables = State(initialValue: CachedResource(key: "d1-tables-\(accountId)-\(databaseId)"))
    }

    var body: some View {
        List {
            Section(.sharedOverview) {
                if let fileSize = database?.fileSize {
                    LabeledContent(.storageSize, value: fileSize.byteFormatted)
                }
                if let createdAt = database?.createdAt {
                    LabeledContent(.workersDetailCreated, value: createdAt.formatted(date: .abbreviated, time: .omitted))
                }
                LabeledContent(.storageD1DatabaseID) {
                    Text(databaseId)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
            }

            Section {
                NavigationLink(value: StorageDestination.d1Query(databaseId: databaseId)) {
                    SettingsLabel(title: .storageD1RunQuery, systemImage: "terminal.fill", color: .gray)
                }
            }

            Section(.storageD1Tables) {
                if tables.value == nil && tables.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let error = tables.error, tables.value == nil {
                    Text(error.localizedDescription)
                        .foregroundStyle(.secondary)
                } else if tables.value?.isEmpty == true {
                    Text(.storageD1TablesEmpty)
                        .foregroundStyle(.secondary)
                }
                ForEach(tables.value ?? [], id: \.self) { table in
                    NavigationLink(value: StorageDestination.d1Table(databaseId: databaseId, table: table)) {
                        Label(table, systemImage: "tablecells")
                    }
                }
            }
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func reload() async {
        await tables.refresh {
            try await client.d1Tables(accountId: accountId, databaseId: databaseId)
        }
    }
}
