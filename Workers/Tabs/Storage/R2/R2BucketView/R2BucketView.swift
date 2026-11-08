import CloudflareKit
import SwiftUI

struct R2BucketView: View {
    let client: CloudflareClient
    let accountId: String
    let bucketName: String
    let prefix: String

    @Environment(R2UploadCenter.self) var uploads

    @State var firstPage: CachedResource<R2ObjectPage>
    @State var additionalObjects: [R2Object] = []
    @State var nextCursor: String?
    @State var isLoadingMore = false
    @State var loadMoreError: String?

    @State var runner = R2OperationRunner()
    @State var editMode = EditMode.inactive
    @State var selection = Set<String>()
    @State var namePrompt: R2NamePrompt?
    @State var pendingDeletion: [R2Entry]?
    @State var pendingUpload: [URL]?
    @State var pendingOversizedUpload: R2OversizedUpload?
    @State var isImportingFiles = false
    @State var downloads: [R2DownloadedObject] = []

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

    var folders: [String] {
        firstPage.value?.folders ?? []
    }

    // Folders created in the dashboard are zero byte objects whose key is the folder prefix.
    var objects: [R2Object] {
        ((firstPage.value?.objects ?? []) + additionalObjects).filter { $0.key != prefix }
    }

    var body: some View {
        List(selection: $selection) {
            RefreshErrorSection(resource: firstPage)
            if !folderUploads.isEmpty {
                R2UploadsSection(uploads: folderUploads, client: client)
            }
            if !folders.isEmpty {
                foldersSection
            }
            if !objects.isEmpty {
                objectsSection
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .environment(\.editMode, $editMode)
        .resourceStatus(firstPage, emptyTitle: .storageR2ObjectsEmpty, emptySystemImage: "folder") { page in
            page.folders.isEmpty && page.objects.allSatisfy { $0.key == prefix } && folderUploads.isEmpty
        }
        .fileImporter(isPresented: $isImportingFiles, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            Task { await prepareUpload(result) }
        }
        .r2NamePrompt($namePrompt)
        .r2FileSaver(downloads: $downloads, runner: runner)
        .modifier(R2BucketConfirmations(
            pendingDeletion: $pendingDeletion,
            pendingUpload: $pendingUpload,
            pendingOversizedUpload: $pendingOversizedUpload,
            delete: { entries in Task { await delete(entries) } },
            upload: { urls in Task { await upload(urls) } },
            continueUpload: { urls in Task { await checkConflicts(urls) } }
        ))
        .r2Operation(runner)
        .task { await reload() }
        .task(id: uploads.completedCount) { await reloadAfterUploads() }
        .refreshable { await reload() }
    }

    func reload() async {
        await firstPage.refresh {
            try await client.r2Objects(accountId: accountId, bucketName: bucketName, prefix: prefix)
        }
        additionalObjects = []
        nextCursor = firstPage.value?.nextCursor
    }

    func loadMore() async {
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
