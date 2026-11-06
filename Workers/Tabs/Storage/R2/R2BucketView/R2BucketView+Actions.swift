import CloudflareKit
import SwiftUI

extension R2BucketView {
    var selectedObjects: [R2Object] {
        objects.filter { selection.contains($0.key) }
    }

    var selectedEntries: [R2Entry] {
        selectedObjects.map(R2Entry.object) + folders.filter(selection.contains).map(R2Entry.folder)
    }

    func promptForNewFolder() {
        namePrompt = R2NamePrompt(
            title: .storageR2NewFolder,
            message: nil,
            actionTitle: .storageR2Create,
            initialName: ""
        ) { name in
            Task { await createFolder(named: name) }
        }
    }

    func promptForRename(_ entry: R2Entry) {
        let isFolder = if case .folder = entry { true } else { false }
        namePrompt = R2NamePrompt(
            title: .storageR2Rename,
            message: isFolder ? .storageR2RenameFolderMessage : .storageR2RenameObjectMessage,
            actionTitle: .storageR2Rename,
            initialName: entry.name
        ) { name in
            Task { await rename(entry, to: name) }
        }
    }

    func createFolder(named name: String) async {
        await runner.run(.storageR2ProgressCreating) {
            try await client.r2CreateFolder(accountId: accountId, bucketName: bucketName, prefix: prefix + name + "/")
        }
        await reload()
    }

    func rename(_ entry: R2Entry, to name: String) async {
        await runner.run(.storageR2ProgressRenaming) {
            switch entry {
            case .object(let object):
                try await client.r2RenameObject(
                    accountId: accountId,
                    bucketName: bucketName,
                    object: object,
                    newKey: prefix + name
                )
            case .folder(let folder):
                try await client.r2RenameFolder(
                    accountId: accountId,
                    bucketName: bucketName,
                    prefix: folder,
                    newPrefix: prefix + name + "/",
                    progress: reportProgress
                )
            }
        }
        await reload()
    }

    func delete(_ entries: [R2Entry]) async {
        let didFinish = await runner.run(.storageR2ProgressDeleting) {
            for (index, entry) in entries.enumerated() {
                try Task.checkCancellation()
                switch entry {
                case .object(let object):
                    runner.report(completed: index, total: entries.count)
                    try await client.r2DeleteObject(accountId: accountId, bucketName: bucketName, key: object.key)
                case .folder(let folder):
                    try await client.r2DeleteFolder(
                        accountId: accountId,
                        bucketName: bucketName,
                        prefix: folder,
                        progress: reportProgress
                    )
                }
            }
        }
        if didFinish {
            finishEditing()
        }
        await reload()
    }

    func save(_ objects: [R2Object]) async {
        var saved: [R2DownloadedObject] = []
        let didFinish = await runner.run(.storageR2ProgressDownloading) {
            for (index, object) in objects.enumerated() {
                try Task.checkCancellation()
                runner.report(completed: index, total: objects.count)
                saved.append(try await client.r2DownloadObject(
                    accountId: accountId,
                    bucketName: bucketName,
                    key: object.key
                ))
            }
        }
        if didFinish {
            finishEditing()
            downloads = saved
        } else {
            saved.forEach { $0.removeTemporaryFile() }
        }
    }

    func prepareUpload(_ result: Result<[URL], Error>) async {
        let urls: [URL]
        switch result {
        case .success(let selectedURLs):
            urls = selectedURLs
        case .failure(let error):
            runner.failureMessage = error.localizedDescription
            return
        }
        var hasConflict = false
        let didFinish = await runner.run(.storageR2ProgressUploading) {
            for url in urls where !hasConflict {
                hasConflict = try await client.r2ObjectExists(
                    accountId: accountId,
                    bucketName: bucketName,
                    key: prefix + url.lastPathComponent
                )
            }
        }
        guard didFinish else { return }
        if hasConflict {
            pendingUpload = urls
        } else {
            await upload(urls)
        }
    }

    func upload(_ urls: [URL]) async {
        await runner.run(.storageR2ProgressUploading) {
            for (index, url) in urls.enumerated() {
                try Task.checkCancellation()
                runner.report(completed: index, total: urls.count)
                let isAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if isAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType?.preferredMIMEType
                try await client.r2UploadObject(
                    accountId: accountId,
                    bucketName: bucketName,
                    key: prefix + url.lastPathComponent,
                    fileURL: url,
                    contentType: contentType
                )
            }
        }
        await reload()
    }

    private var reportProgress: @MainActor @Sendable (Int, Int) -> Void {
        { [runner] completed, total in
            runner.report(completed: completed, total: total)
        }
    }

    private func finishEditing() {
        selection = []
        editMode = .inactive
    }
}
