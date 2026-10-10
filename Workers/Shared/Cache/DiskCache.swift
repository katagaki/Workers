import CloudflareKit
import Foundation

final class DiskCache {
    static let shared = DiskCache()

    private let directory: URL
    private var memory: [String: Data] = [:]
    private let encoder = CloudflareJSON.makeEncoder()
    private let decoder = CloudflareJSON.makeDecoder()

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directory = caches.appendingPathComponent("CloudflareCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func value<Value: Decodable>(for key: String, as type: Value.Type = Value.self) -> CacheEntry<Value>? {
        let data: Data
        if let cached = memory[key] {
            data = cached
        } else if let stored = try? Data(contentsOf: fileURL(for: key)) {
            memory[key] = stored
            data = stored
        } else {
            return nil
        }
        return try? decoder.decode(CacheEntry<Value>.self, from: data)
    }

    func store<Value: Encodable>(_ value: Value, for key: String) {
        guard let data = try? encoder.encode(CacheEntry(savedAt: .now, value: value)) else { return }
        memory[key] = data
        let url = fileURL(for: key)
        Task.detached(priority: .utility) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func clear() {
        memory.removeAll()
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func fileURL(for key: String) -> URL {
        let safeName = key.map { $0.isLetter || $0.isNumber || $0 == "-" ? String($0) : "_" }.joined()
        return directory.appendingPathComponent(safeName).appendingPathExtension("json")
    }
}
