import CloudflareKit
import Foundation
import Observation

@Observable
final class R2UploadCenter {
    static let shared = R2UploadCenter()

    private(set) var records: [R2Upload] = []
    private(set) var completedCount = 0

    @ObservationIgnored var backgroundEventsCompletion: (() -> Void)?

    @ObservationIgnored private let uploader = R2BackgroundUploader.shared
    @ObservationIgnored private var demoTasks: [UUID: Task<Void, Never>] = [:]

    private init() {
        records = Self.loadRecords()
        R2UploadStaging.removeOrphans(keeping: Set(records.map(\.id)))
        Task { await reconcile() }
        Task {
            for await event in uploader.events {
                handle(event)
            }
        }
    }

    func enqueue(
        _ sourceURL: URL,
        client: CloudflareClient,
        accountId: String,
        bucketName: String,
        key: String
    ) async throws {
        let id = UUID()
        let contentType = try? sourceURL.resourceValues(forKeys: [.contentTypeKey]).contentType?.preferredMIMEType
        try await Task.detached { try R2UploadStaging.stage(sourceURL, id: id) }.value
        let fileURL = R2UploadStaging.fileURL(for: id)
        let fileSize = try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        let upload = R2Upload(
            id: id,
            accountId: accountId,
            bucketName: bucketName,
            key: key,
            contentType: contentType,
            totalBytes: Int64(fileSize),
            isDemo: client.isDemo
        )
        do {
            try start(upload, client: client)
        } catch {
            R2UploadStaging.remove(id: id)
            throw error
        }
        records.append(upload)
        persist()
    }

    func retry(_ upload: R2Upload, client: CloudflareClient) {
        guard FileManager.default.fileExists(atPath: R2UploadStaging.fileURL(for: upload.id).path) else { return }
        do {
            try start(upload, client: client)
            update(upload.id) {
                $0.sentBytes = 0
                $0.failureMessage = nil
            }
        } catch {
            update(upload.id) { $0.failureMessage = error.localizedDescription }
        }
        persist()
    }

    func remove(_ upload: R2Upload) {
        demoTasks.removeValue(forKey: upload.id)?.cancel()
        finish(upload.id)
        Task { await uploader.cancel(id: upload.id) }
    }

    func removeAll() {
        records.map(\.id).forEach(finish)
        demoTasks.values.forEach { $0.cancel() }
        demoTasks = [:]
        Task { await uploader.cancelAll() }
    }

    private func start(_ upload: R2Upload, client: CloudflareClient) throws {
        let fileURL = R2UploadStaging.fileURL(for: upload.id)
        if client.isDemo {
            startDemo(upload, client: client, fileURL: fileURL)
            return
        }
        let request = try client.r2UploadRequest(
            accountId: upload.accountId,
            bucketName: upload.bucketName,
            key: upload.key,
            fileSize: Int(upload.totalBytes),
            contentType: upload.contentType
        )
        uploader.start(id: upload.id, request: request, fileURL: fileURL)
    }

    // Background sessions reject custom URL protocols, so demo uploads run in process.
    private func startDemo(_ upload: R2Upload, client: CloudflareClient, fileURL: URL) {
        demoTasks[upload.id] = Task {
            do {
                for step in 1...20 {
                    try await Task.sleep(for: .milliseconds(150))
                    handle(.progress(id: upload.id, sentBytes: upload.totalBytes * Int64(step) / 20))
                }
                try await client.r2UploadObject(
                    accountId: upload.accountId,
                    bucketName: upload.bucketName,
                    key: upload.key,
                    fileURL: fileURL,
                    contentType: upload.contentType
                )
                handle(.finished(id: upload.id, failureMessage: nil))
            } catch is CancellationError {
                return
            } catch {
                handle(.finished(id: upload.id, failureMessage: error.localizedDescription))
            }
        }
    }

    private func handle(_ event: R2UploadEvent) {
        switch event {
        case .progress(let id, let sentBytes):
            update(id) { $0.sentBytes = sentBytes }
        case .finished(let id, let failureMessage):
            guard records.contains(where: { $0.id == id }) else { return }
            demoTasks[id] = nil
            if let failureMessage {
                update(id) { $0.failureMessage = failureMessage }
                persist()
            } else {
                finish(id)
                completedCount += 1
            }
        case .backgroundEventsDelivered:
            backgroundEventsCompletion?()
            backgroundEventsCompletion = nil
        }
    }

    private func finish(_ id: UUID) {
        records.removeAll { $0.id == id }
        R2UploadStaging.remove(id: id)
        persist()
    }

    private func update(_ id: UUID, _ transform: (inout R2Upload) -> Void) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        transform(&records[index])
    }

    // Finished events for uploads that ended while the app was gone still arrive after this runs.
    private func reconcile() async {
        let activeUploads = await uploader.activeUploads()
        let activeBytes = Dictionary(activeUploads.map { ($0.id, $0.sentBytes) }, uniquingKeysWith: max)
        for record in records where record.failureMessage == nil {
            if let sentBytes = activeBytes[record.id] {
                update(record.id) { $0.sentBytes = sentBytes }
            } else {
                update(record.id) { $0.failureMessage = String(localized: .storageR2UploadsInterrupted) }
            }
        }
        persist()
        let knownIds = Set(records.map(\.id))
        for upload in activeUploads where !knownIds.contains(upload.id) {
            await uploader.cancel(id: upload.id)
        }
    }

    private func persist() {
        let stored = records.filter { !$0.isDemo }
        if stored.isEmpty {
            try? FileManager.default.removeItem(at: R2UploadStaging.recordsURL)
        } else if let data = try? JSONEncoder().encode(stored) {
            try? FileManager.default.createDirectory(at: R2UploadStaging.directory, withIntermediateDirectories: true)
            try? data.write(to: R2UploadStaging.recordsURL, options: .atomic)
        }
    }

    private static func loadRecords() -> [R2Upload] {
        guard let data = try? Data(contentsOf: R2UploadStaging.recordsURL) else { return [] }
        return (try? JSONDecoder().decode([R2Upload].self, from: data)) ?? []
    }
}
