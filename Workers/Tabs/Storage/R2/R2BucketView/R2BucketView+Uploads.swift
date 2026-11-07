import CloudflareKit
import SwiftUI

extension R2BucketView {
    var folderUploads: [R2Upload] {
        uploads.records.filter {
            $0.accountId == accountId && $0.bucketName == bucketName && $0.key.r2ParentPrefix == prefix
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
        let oversizedURLs = urls.filter { fileSize(of: $0) > CloudflareClient.r2UploadLimit }
        guard oversizedURLs.isEmpty else {
            pendingOversizedUpload = R2OversizedUpload(
                fileNames: oversizedURLs.map(\.lastPathComponent),
                remainingURLs: urls.filter { !oversizedURLs.contains($0) }
            )
            return
        }
        await checkConflicts(urls)
    }

    func checkConflicts(_ urls: [URL]) async {
        var hasConflict = false
        let didFinish = await runner.run(.storageR2ProgressPreparing) {
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
        await runner.run(.storageR2ProgressPreparing) {
            for (index, url) in urls.enumerated() {
                try Task.checkCancellation()
                runner.report(completed: index, total: urls.count)
                try await uploads.enqueue(
                    url,
                    client: client,
                    accountId: accountId,
                    bucketName: bucketName,
                    key: prefix + url.lastPathComponent
                )
            }
        }
    }

    func reloadAfterUploads() async {
        guard uploads.completedCount > 0 else { return }
        var reloadedCount: Int
        repeat {
            reloadedCount = uploads.completedCount
            while firstPage.isLoading {
                try? await Task.sleep(for: .milliseconds(100))
            }
            await reload()
        } while reloadedCount != uploads.completedCount
    }

    private func fileSize(of url: URL) -> Int {
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
    }
}
