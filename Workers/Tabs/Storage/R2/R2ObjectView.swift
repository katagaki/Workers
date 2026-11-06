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
    @State private var runner = R2OperationRunner()
    @State private var namePrompt: R2NamePrompt?
    @State private var isConfirmingDelete = false
    @State private var downloads: [R2DownloadedObject] = []

    @Environment(\.dismiss) private var dismiss

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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                actionsMenu
            }
        }
        .alert(Text(.storageR2DeleteTitle), isPresented: $isConfirmingDelete) {
            Button(role: .cancel) {}
            Button(.sharedDelete, role: .destructive) {
                Task { await delete() }
            }
        } message: {
            Text(.storageR2DeleteObjectMessage(object.key.r2Name))
        }
        .r2NamePrompt($namePrompt)
        .r2FileSaver(downloads: $downloads, runner: runner)
        .r2Operation(runner)
        .task {
            if (object.size ?? 0) <= Self.automaticPreviewLimit {
                await load()
            }
        }
    }

    private var actionsMenu: some View {
        Menu {
            Button {
                Task { await save() }
            } label: {
                Label(.storageR2SaveToFiles, systemImage: "square.and.arrow.down")
            }
            Button {
                promptForRename()
            } label: {
                Label(.storageR2Rename, systemImage: "pencil")
            }
            Button(role: .destructive) {
                isConfirmingDelete = true
            } label: {
                Label(.sharedDelete, systemImage: "trash")
            }
        } label: {
            Label(.sharedMore, systemImage: "ellipsis")
        }
    }

    private func promptForRename() {
        namePrompt = R2NamePrompt(
            title: .storageR2Rename,
            message: .storageR2RenameObjectMessage,
            actionTitle: .storageR2Rename,
            initialName: object.key.r2Name
        ) { name in
            Task { await rename(to: name) }
        }
    }

    private func save() async {
        await runner.run(.storageR2ProgressDownloading) {
            downloads = [try await client.r2DownloadObject(
                accountId: accountId,
                bucketName: bucketName,
                key: object.key
            )]
        }
    }

    private func rename(to name: String) async {
        let didFinish = await runner.run(.storageR2ProgressRenaming) {
            try await client.r2RenameObject(
                accountId: accountId,
                bucketName: bucketName,
                object: object,
                newKey: object.key.r2ParentPrefix + name
            )
        }
        if didFinish {
            dismiss()
        }
    }

    private func delete() async {
        let didFinish = await runner.run(.storageR2ProgressDeleting) {
            try await client.r2DeleteObject(accountId: accountId, bucketName: bucketName, key: object.key)
        }
        if didFinish {
            dismiss()
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
