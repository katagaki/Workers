import CloudflareKit
import SwiftUI

struct KVValueView: View {
    let client: CloudflareClient
    let accountId: String
    let namespaceId: String
    let key: KVKey

    @State private var data: Data?
    @State private var loadError: Error?

    var body: some View {
        List {
            Section(.sharedOverview) {
                LabeledContent(.storageKvKey) {
                    Text(key.name)
                        .textSelection(.enabled)
                }
                if let expiration = key.expiration {
                    LabeledContent(.storageKvExpiration, value: expiration.formatted(date: .abbreviated, time: .shortened))
                }
                if let data {
                    LabeledContent(.storageSize, value: data.count.byteFormatted)
                }
            }
            if let metadata = key.metadata, metadata != .null {
                Section(.storageKvMetadata) {
                    Text(metadata.displayText)
                        .font(.callout)
                        .textSelection(.enabled)
                }
            }
            if let data {
                StoredDataPreview(data: data, fileName: key.name)
            } else if let loadError {
                Section(.storageValue) {
                    Text(loadError.localizedDescription)
                        .foregroundStyle(.secondary)
                }
            } else {
                Section(.storageValue) {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle(key.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            data = try await client.kvValue(accountId: accountId, namespaceId: namespaceId, key: key.name)
            loadError = nil
        } catch {
            loadError = error
        }
    }
}
