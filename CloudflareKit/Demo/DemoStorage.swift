import Foundation

enum DemoStorage {
    static let kvNamespaces: [(id: String, title: String)] = [
        (DemoData.hex(900), "schale-gateway-CACHE"),
        (DemoData.hex(902), "momotalk-auth-SESSIONS"),
        (DemoData.hex(903), "feature-flags")
    ]

    static func kvKeys(namespaceId: String, prefix: String?) -> [[String: Any]] {
        let keys: [(String, Any)]
        switch namespaceId {
        case DemoData.hex(902):
            keys = (1...24).map { index in
                ("session:\(DemoData.hex(index + 4000, length: 12))", ["student": "user-\(index)", "issued": DemoData.ago(hours: Double(index))])
            }
        case DemoData.hex(903):
            keys = [
                ("flags/momotalk/stickers", ["enabled": true, "rollout": 100]),
                ("flags/momotalk/voice-notes", ["enabled": true, "rollout": 25]),
                ("flags/schale/new-dashboard", ["enabled": false, "rollout": 0]),
                ("maintenance-message", "Scheduled maintenance for the Millennium servers is on Sunday at 03:00.")
            ]
        default:
            keys = [
                ("route:/api/students", ["status": 200, "count": 42]),
                ("route:/api/clubs", ["status": 200, "count": 18]),
                ("route:/api/notices", ["status": 200, "count": 7]),
                ("banner.png", "PNG")
            ]
        }
        return keys
            .filter { prefix == nil || $0.0.hasPrefix(prefix ?? "") }
            .map { key in
                var object: [String: Any] = ["name": key.0]
                if key.0.hasPrefix("session:") {
                    object["expiration"] = Int(Date.now.timeIntervalSince1970) + 86_400
                }
                return object
            }
    }

    static func kvValue(namespaceId: String, key: String) -> Data {
        if key == "maintenance-message" {
            return Data("Scheduled maintenance for the Millennium servers is on Sunday at 03:00.".utf8)
        }
        let value: [String: Any] = [
            "key": key,
            "cachedAt": DemoData.ago(hours: 1),
            "source": "schale-gateway",
            "payload": ["students": ["Hoshino", "Shiroko", "Yuuka"]]
        ]
        return (try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])) ?? Data()
    }

    static var buckets: [[String: Any]] { [
        ["name": "originals", "creation_date": DemoData.ago(hours: 24 * 300), "location": "APAC", "storage_class": "Standard"],
        ["name": "momotalk-attachments", "creation_date": DemoData.ago(hours: 24 * 180), "location": "APAC", "storage_class": "Standard"],
        ["name": "schale-backups", "creation_date": DemoData.ago(hours: 24 * 90), "location": "WEUR", "storage_class": "InfrequentAccess"]
    ] }

    static func r2Objects(bucketName: String, prefix: String) -> [String: Any] {
        let allKeys: [(String, Int, String)] = [
            ("students/hoshino.json", 2_340, "application/json"),
            ("students/shiroko.json", 2_112, "application/json"),
            ("students/yuuka.json", 1_984, "application/json"),
            ("notices/2026-10-01.txt", 820, "text/plain"),
            ("notices/2026-10-08.txt", 1_204, "text/plain"),
            ("README.txt", 312, "text/plain"),
            ("\(bucketName)-manifest.json", 4_096, "application/json")
        ]
        var folders = Set<String>()
        var objects: [[String: Any]] = []
        for (index, entry) in allKeys.enumerated() where entry.0.hasPrefix(prefix) {
            let remainder = entry.0.dropFirst(prefix.count)
            if let slash = remainder.firstIndex(of: "/") {
                folders.insert(prefix + remainder[...slash])
            } else {
                objects.append([
                    "key": entry.0,
                    "size": entry.1,
                    "etag": DemoData.hex(index + 7000),
                    "last_modified": DemoData.ago(hours: Double(index * 9 + 2)),
                    "http_metadata": ["contentType": entry.2],
                    "storage_class": "Standard"
                ])
            }
        }
        return DemoRouter.envelope(objects, info: ["is_truncated": false, "delimited": folders.sorted(), "per_page": 100])
    }

    static func r2ObjectData(key: String) -> Data {
        if key.hasSuffix(".json") {
            return kvValue(namespaceId: "", key: key)
        }
        return Data("Notice from the General Student Council about \(key).".utf8)
    }

    static var databases: [[String: Any]] { [
        ["uuid": DemoData.hex(901), "name": "momotalk-auth-db", "version": "production", "created_at": DemoData.ago(hours: 24 * 210), "file_size": 2_457_600, "num_tables": 3],
        ["uuid": DemoData.hex(904), "name": "schale-notices", "version": "production", "created_at": DemoData.ago(hours: 24 * 60), "file_size": 409_600, "num_tables": 1]
    ] }

    static func d1Query(sql: String) -> [String: Any] {
        let columns: [String]
        let rows: [[Any]]
        let lowered = sql.lowercased()
        if lowered.contains("sqlite_master") {
            columns = ["name"]
            rows = [["accounts"], ["clubs"], ["sessions"]]
        } else if lowered.contains("clubs") {
            columns = ["id", "name", "school", "members"]
            rows = [
                [1, "Foreclosure Task Force", "Abydos", 5],
                [2, "Game Development Department", "Millennium", 4],
                [3, "Problem Solver 68", "Gehenna", 4]
            ]
        } else if lowered.contains("sessions") {
            columns = ["id", "account_id", "expires_at"]
            rows = (1...8).map { [DemoData.hex($0 + 4000, length: 12), $0, DemoData.ago(hours: Double(-$0))] }
        } else {
            columns = ["id", "name", "school", "created_at"]
            rows = [
                [1, "Takanashi Hoshino", "Abydos", DemoData.ago(hours: 24 * 120)],
                [2, "Sunaookami Shiroko", "Abydos", DemoData.ago(hours: 24 * 118)],
                [3, "Hayase Yuuka", "Millennium", DemoData.ago(hours: 24 * 90)],
                [4, "Rikuhachima Aru", "Gehenna", DemoData.ago(hours: 24 * 60)]
            ]
        }
        return DemoRouter.envelope([[
            "results": ["columns": columns, "rows": rows],
            "meta": ["duration": 0.42, "rows_read": rows.count, "rows_written": 0, "changes": 0],
            "success": true
        ]])
    }
}
