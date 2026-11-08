import Foundation

final class DemoR2Store: @unchecked Sendable {
    private struct Entry {
        let key: String
        let size: Int
        let contentType: String
    }

    static let shared = DemoR2Store()
    private let lock = NSLock()
    private var buckets: [String: [String: Entry]] = [:]

    func list(bucketName: String, prefix: String, delimiter: String?) -> [String: Any] {
        lock.withLock {
            var folders = Set<String>()
            var objects: [[String: Any]] = []
            let sortedEntries = storedEntries(in: bucketName).values.sorted { $0.key < $1.key }
            for (index, entry) in sortedEntries.enumerated() where entry.key.hasPrefix(prefix) {
                let remainder = entry.key.dropFirst(prefix.count)
                if delimiter != nil, let slash = remainder.firstIndex(of: "/") {
                    folders.insert(prefix + remainder[...slash])
                } else {
                    objects.append([
                        "key": entry.key,
                        "size": entry.size,
                        "etag": DemoData.hex(index + 7000),
                        "last_modified": DemoData.ago(hours: Double(index * 9 + 2)),
                        "http_metadata": ["contentType": entry.contentType],
                        "storage_class": "Standard"
                    ])
                }
            }
            return DemoRouter.envelope(objects, info: ["is_truncated": false, "delimited": folders.sorted(), "per_page": 100])
        }
    }

    func data(bucketName: String, key: String) -> Data {
        lock.withLock {
            let content = key.hasSuffix(".json")
                ? DemoStorage.kvValue(namespaceId: "", key: key)
                : Data("Notice from the General Student Council about \(key).".utf8)
            guard let size = storedEntries(in: bucketName)[key]?.size else { return content }
            let padding = Data(repeating: 0x20, count: max(0, size - content.count))
            return content.prefix(size) + padding
        }
    }

    func write(method: String, bucketName: String, key: String, headers: [String: String]) -> [String: Any] {
        lock.withLock {
            var entries = storedEntries(in: bucketName)
            switch method {
            case "PUT":
                entries[key] = Entry(
                    key: key,
                    size: headers["Content-Length"].flatMap(Int.init) ?? 0,
                    contentType: headers["Content-Type"] ?? "application/octet-stream"
                )
            case "DELETE":
                entries[key] = nil
            default:
                return DemoRouter.envelope(nil, errors: [["code": 7003, "message": "Not available in demo mode."]])
            }
            buckets[bucketName] = entries
            return DemoRouter.envelope(NSNull())
        }
    }

    private func storedEntries(in bucketName: String) -> [String: Entry] {
        if let existing = buckets[bucketName] { return existing }
        let seeded: [Entry] = [
            Entry(key: "students/hoshino.json", size: 2_340, contentType: "application/json"),
            Entry(key: "students/shiroko.json", size: 2_112, contentType: "application/json"),
            Entry(key: "students/yuuka.json", size: 1_984, contentType: "application/json"),
            Entry(key: "notices/2026-10-01.txt", size: 820, contentType: "text/plain"),
            Entry(key: "notices/2026-10-08.txt", size: 1_204, contentType: "text/plain"),
            Entry(key: "README.txt", size: 312, contentType: "text/plain"),
            Entry(key: "\(bucketName)-manifest.json", size: 4_096, contentType: "application/json")
        ]
        let entries = Dictionary(uniqueKeysWithValues: seeded.map { ($0.key, $0) })
        buckets[bucketName] = entries
        return entries
    }
}
