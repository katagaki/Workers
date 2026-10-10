import CloudflareKit
import SwiftUI

struct R2BucketView: View {
    let client: CloudflareClient
    let accountId: String
    let bucketName: String
    let prefix: String

    @State private var firstPage: CachedResource<R2ObjectPage>
    @State private var additionalObjects: [R2Object] = []
    @State private var nextCursor: String?
    @State private var isLoadingMore = false
    @State private var loadMoreError: String?

    init(client: CloudflareClient, accountId: String, bucketName: String, prefix: String = "") {
        self.client = client
        self.accountId = accountId
        self.bucketName = bucketName
        self.prefix = prefix
        _firstPage = State(initialValue: CachedResource(key: "r2-objects-\(accountId)-\(bucketName)-\(prefix)"))
    }

    private var title: String {
        guard !prefix.isEmpty else { return bucketName }
        return prefix.split(separator: "/").last.map(String.init) ?? bucketName
    }

    private var objects: [R2Object] {
        (firstPage.value?.objects ?? []) + additionalObjects
    }

    var body: some View {
        List {
            RefreshErrorSection(resource: firstPage)
            if let folders = firstPage.value?.folders, !folders.isEmpty {
                Section(.storageR2Folders) {
                    ForEach(folders, id: \.self) { folder in
                        NavigationLink(value: StorageDestination.r2Bucket(bucketName: bucketName, prefix: folder)) {
                            Label {
                                Text(folder.dropFirst(prefix.count).dropLast())
                                    .lineLimit(1)
                            } icon: {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            if !objects.isEmpty {
                Section {
                    ForEach(objects) { object in
                        NavigationLink(value: StorageDestination.r2Object(bucketName: bucketName, object: object)) {
                            R2ObjectRow(object: object, prefix: prefix)
                        }
                    }
                    if nextCursor != nil {
                        LoadMoreButton(isLoading: isLoadingMore) { await loadMore() }
                    }
                } header: {
                    Text(.storageR2Objects)
                } footer: {
                    if let loadMoreError {
                        Text(loadMoreError)
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .resourceStatus(firstPage, emptyTitle: .storageR2ObjectsEmpty, emptySystemImage: "folder") { page in
            page.objects.isEmpty && page.folders.isEmpty
        }
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func reload() async {
        await firstPage.refresh {
            try await client.r2Objects(accountId: accountId, bucketName: bucketName, prefix: prefix)
        }
        additionalObjects = []
        nextCursor = firstPage.value?.nextCursor
    }

    private func loadMore() async {
        guard let cursor = nextCursor else { return }
        isLoadingMore = true
        loadMoreError = nil
        defer { isLoadingMore = false }
        do {
            let page = try await client.r2Objects(accountId: accountId, bucketName: bucketName, prefix: prefix, cursor: cursor)
            additionalObjects += page.objects
            nextCursor = page.nextCursor
        } catch {
            loadMoreError = error.localizedDescription
        }
    }
}
