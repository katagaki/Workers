import CloudflareKit
import SwiftUI

struct D1TableView: View {
    let client: CloudflareClient
    let accountId: String
    let databaseId: String
    let table: String

    @State private var preview: CachedResource<D1QueryResult>

    init(client: CloudflareClient, accountId: String, databaseId: String, table: String) {
        self.client = client
        self.accountId = accountId
        self.databaseId = databaseId
        self.table = table
        _preview = State(initialValue: CachedResource(key: "d1-table-\(accountId)-\(databaseId)-\(table)"))
    }

    var body: some View {
        List {
            RefreshErrorSection(resource: preview)
            if let result = preview.value {
                D1ResultSection(result: result, footer: .storageD1PreviewFooter)
            }
        }
        .navigationTitle(table)
        .navigationBarTitleDisplayMode(.inline)
        .resourceStatus(preview, emptyTitle: .storageD1NoRows, emptySystemImage: "tablecells") { $0.rows.isEmpty }
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func reload() async {
        await preview.refresh {
            try await client.d1TablePreview(accountId: accountId, databaseId: databaseId, table: table)
        }
    }
}
