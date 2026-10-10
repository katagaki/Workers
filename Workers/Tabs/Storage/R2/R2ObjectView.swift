import CloudflareKit
import SwiftUI

struct R2ObjectView: View {
    let client: CloudflareClient
    let accountId: String
    let bucketName: String
    let object: R2Object

    @State private var data: Data?
    @State private var loadError: Error?
    @State private var isLoading = false

    private static let automaticPreviewLimit = 1_000_000

    var body: some View {
        List {
            Section(.sharedOverview) {
                LabeledContent(.storageR2Key) {
                    Text(object.key)
                        .textSelection(.enabled)
                }
                if let size = object.size {
                    LabeledContent(.storageSize, value: size.byteFormatted)
                }
                if let contentType = object.httpMetadata?.contentType {
                    LabeledContent(.storageR2ContentType, value: contentType)
                }
                if let lastModified = object.lastModified {
                    LabeledContent(.storageR2LastModified, value: lastModified.formatted(date: .abbreviated, time: .shortened))
                }
                if let storageClass = object.storageClass {
                    LabeledContent(.storageR2StorageClass, value: storageClass)
                }
                if let etag = object.etag {
                    LabeledContent(.storageR2Etag) {
                        Text(etag)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                    }
                }
            }
            if let data {
                StoredDataPreview(data: data, fileName: object.key)
            } else {
                Section {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Button {
                            Task { await load() }
                        } label: {
                            Label(.storageR2LoadPreview, systemImage: "arrow.down.circle")
                        }
                    }
                } header: {
                    Text(.storageValue)
                } footer: {
                    if let loadError {
                        Text(loadError.localizedDescription)
                    } else if let size = object.size, size > Self.automaticPreviewLimit {
                        Text(.storageR2LargeObject(size.byteFormatted))
                    }
                }
            }
        }
        .navigationTitle(object.key.split(separator: "/").last.map(String.init) ?? object.key)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if (object.size ?? 0) <= Self.automaticPreviewLimit {
                await load()
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            data = try await client.r2ObjectData(accountId: accountId, bucketName: bucketName, key: object.key)
            loadError = nil
        } catch {
            loadError = error
        }
    }
}
