import Foundation

// The system uploads from its own process, which can't reach files picked from other apps later.
nonisolated enum R2UploadStaging {
    static var directory: URL {
        URL.applicationSupportDirectory.appendingPathComponent("R2Uploads", isDirectory: true)
    }

    static var recordsURL: URL {
        directory.appendingPathComponent("records.json")
    }

    static func fileURL(for id: UUID) -> URL {
        directory.appendingPathComponent(id.uuidString)
    }

    static func stage(_ sourceURL: URL, id: UUID) throws {
        let isAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }
        var directoryURL = directory
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try directoryURL.setResourceValues(resourceValues)

        let destinationURL = fileURL(for: id)
        var coordinationError: NSError?
        var copyError: Error?
        NSFileCoordinator().coordinate(readingItemAt: sourceURL, options: .withoutChanges, error: &coordinationError) { url in
            do {
                try FileManager.default.copyItem(at: url, to: destinationURL)
                // Uploads must keep reading this file while the device is locked.
                try FileManager.default.setAttributes(
                    [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                    ofItemAtPath: destinationURL.path
                )
            } catch {
                copyError = error
            }
        }
        if let error = coordinationError ?? copyError {
            remove(id: id)
            throw error
        }
    }

    static func remove(id: UUID) {
        try? FileManager.default.removeItem(at: fileURL(for: id))
    }

    static func removeOrphans(keeping ids: Set<UUID>) {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        for name in names {
            if let id = UUID(uuidString: name), !ids.contains(id) {
                remove(id: id)
            }
        }
    }
}
