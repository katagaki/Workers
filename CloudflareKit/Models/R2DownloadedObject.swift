import Foundation

public struct R2DownloadedObject: Sendable {
    public let fileURL: URL
    let headers: [String: String]

    public func removeTemporaryFile() {
        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }
}
