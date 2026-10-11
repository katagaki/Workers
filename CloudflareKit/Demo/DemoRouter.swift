import Foundation

enum DemoRouter {
    static func rawResponse(method: String, url: URL) -> Data? {
        let prefix = CloudflareClient.apiBaseURL.path()
        let path = String(url.path().dropFirst(prefix.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let parts = path.split(separator: "/").map { String($0).removingPercentEncoding ?? String($0) }
        guard method == "GET", parts.first == "accounts" else { return nil }
        if parts.count == 8, parts[2] == "storage", parts[6] == "values" {
            return DemoStorage.kvValue(namespaceId: parts[5], key: parts[7])
        }
        if parts.count == 7, parts[2] == "r2", parts[5] == "objects" {
            return DemoStorage.r2ObjectData(key: parts[6])
        }
        return nil
    }

    static func response(method: String, url: URL, body: Data?) -> [String: Any] {
        let prefix = CloudflareClient.apiBaseURL.path()
        let path = String(url.path().dropFirst(prefix.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let parts = path.split(separator: "/").map { String($0).removingPercentEncoding ?? String($0) }
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let bodyObject = body.flatMap { try? JSONSerialization.jsonObject(with: $0) }

        if parts == ["graphql"] {
            let queryText = (bodyObject as? [String: Any])?["query"] as? String ?? ""
            return ["data": DemoAnalytics.response(for: queryText)]
        }
        guard let result = route(method: method, parts: parts, query: query, body: bodyObject as? [String: Any]) else {
            return envelope(nil, errors: [["code": 7003, "message": "Not available in demo mode."]])
        }
        return result
    }

    private static func route(
        method: String,
        parts: [String],
        query: [URLQueryItem],
        body: [String: Any]?
    ) -> [String: Any]? {
        switch (method, parts.count, parts.first) {
        case ("GET", 3, "user") where parts[2] == "verify":
            return envelope(["id": DemoData.hex(1), "status": "active"])
        case ("GET", 1, "accounts"):
            return envelope([[
                "id": DemoData.accountId,
                "name": "Kivotos Cloud",
                "type": "standard",
                "created_on": DemoData.ago(hours: 24 * 400)
            ], [
                "id": DemoData.hex(2),
                "name": "Seminar East",
                "type": "standard",
                "created_on": DemoData.ago(hours: 24 * 200)
            ]], info: ["page": 1, "per_page": 50, "count": 2, "total_count": 2, "total_pages": 1])
        case (_, _, "accounts") where parts.count >= 3:
            return accountRoute(method: method, parts: Array(parts.dropFirst(2)), query: query, body: body)
        case ("GET", 1, "zones"):
            let zones = DemoData.zones.map(DemoResources.zone)
            return envelope(zones, info: ["page": 1, "per_page": 50, "count": zones.count, "total_count": zones.count, "total_pages": 1])
        case (_, _, "zones") where parts.count >= 2:
            return zoneRoute(method: method, zoneId: parts[1], parts: Array(parts.dropFirst(2)), body: body)
        default:
            return nil
        }
    }

    private static func accountRoute(
        method: String,
        parts: [String],
        query: [URLQueryItem],
        body: [String: Any]?
    ) -> [String: Any]? {
        if parts.first == "ai" {
            return DemoAIPlayground.response(method: method, parts: parts, body: body)
        }
        switch (method, parts) {
        case ("GET", ["workers", "scripts"]):
            return envelope(DemoData.scripts.map(DemoResources.script))
        case ("GET", ["workers", "subdomain"]):
            return envelope(["subdomain": "kivotos"])
        case ("GET", ["workers", "domains"]):
            return envelope(DemoResources.customDomains)
        case ("GET", ["workers", "durable_objects", "namespaces"]):
            let namespaces = DemoData.namespaces.map(DemoResources.namespace)
            return envelope(namespaces, info: ["page": 1, "per_page": 100, "count": namespaces.count, "total_count": namespaces.count, "total_pages": 1])
        case ("GET", let path) where path.count == 5 && path[0] == "workers" && path[2] == "namespaces" && path[4] == "objects":
            let cursor = query.first { $0.name == "cursor" }?.value
            return DemoResources.objects(namespaceId: path[3], cursor: cursor)
        case ("POST", ["workers", "observability", "telemetry", "query"]):
            let parameters = body?["parameters"] as? [String: Any]
            let filters = parameters?["filters"] as? [[String: Any]]
            let scriptName = filters?.first?["value"] as? String
            return envelope(["events": ["events": DemoResources.events(scriptName: scriptName)]])
        case ("GET", ["storage", "kv", "namespaces"]):
            let namespaces = DemoStorage.kvNamespaces.map { ["id": $0.id, "title": $0.title] }
            return envelope(namespaces, info: ["page": 1, "per_page": 100, "count": namespaces.count, "total_count": namespaces.count, "total_pages": 1])
        case ("GET", let path) where path.count == 5 && path[0] == "storage" && path[4] == "keys":
            let prefix = query.first { $0.name == "prefix" }?.value
            return envelope(DemoStorage.kvKeys(namespaceId: path[3], prefix: prefix), info: ["cursor": ""])
        case ("GET", ["r2", "buckets"]):
            return envelope(["buckets": DemoStorage.buckets])
        case ("GET", let path) where path.count == 4 && path[0] == "r2" && path[3] == "objects":
            let prefix = query.first { $0.name == "prefix" }?.value ?? ""
            return DemoStorage.r2Objects(bucketName: path[2], prefix: prefix)
        case ("GET", ["d1", "database"]):
            let databases = DemoStorage.databases
            return envelope(databases, info: ["page": 1, "per_page": 100, "count": databases.count, "total_count": databases.count, "total_pages": 1])
        case ("POST", let path) where path.count == 4 && path[0] == "d1" && path[3] == "raw":
            return DemoStorage.d1Query(sql: body?["sql"] as? String ?? "")
        case (_, let path) where path.count >= 3 && path[0] == "workers" && path[1] == "scripts":
            return scriptRoute(method: method, scriptName: path[2], parts: Array(path.dropFirst(3)), body: body)
        default:
            return nil
        }
    }

    private static func scriptRoute(method: String, scriptName: String, parts: [String], body: [String: Any]?) -> [String: Any]? {
        guard let script = DemoData.scripts.first(where: { $0.name == scriptName }) else { return nil }
        switch (method, parts) {
        case ("DELETE", []):
            return envelope(NSNull())
        case ("GET", ["deployments"]), ("POST", ["deployments"]):
            return DemoDeployments.shared.response(method: method, script: script, body: body)
        case ("GET", ["versions"]):
            return envelope(["items": DemoResources.versions(for: script)])
        case ("GET", ["settings"]):
            return envelope(DemoResources.settings(for: script))
        case ("GET", ["schedules"]):
            return envelope(["schedules": DemoResources.schedules(for: script)])
        case ("GET", ["subdomain"]):
            return envelope(["enabled": script.name != "wildhunt-visitor-management", "previews_enabled": true])
        case ("POST", ["tails"]):
            return envelope(["id": DemoData.hex(77), "url": "wss://demo.invalid/tail", "expires_at": DemoData.ago(hours: -6)])
        case ("DELETE", let path) where path.first == "tails":
            return envelope(NSNull())
        default:
            return nil
        }
    }

    private static func zoneRoute(method: String, zoneId: String, parts: [String], body: [String: Any]?) -> [String: Any]? {
        guard let zone = DemoData.zones.first(where: { $0.id == zoneId }) else { return nil }
        if parts.first == "rulesets" {
            return DemoSecurity.shared.response(method: method, zoneId: zoneId, parts: parts, body: body)
        }
        if parts == ["settings", "security_level"] {
            return DemoZoneActions.shared.securityLevel(zoneId: zoneId, method: method, body: body)
        }
        switch (method, parts) {
        case ("GET", []):
            return DemoZoneActions.shared.zone(zone, method: method, body: body)
        case ("PATCH", []):
            return DemoZoneActions.shared.zone(zone, method: method, body: body)
        case ("POST", ["purge_cache"]):
            return envelope(["id": zoneId])
        case ("GET", ["dns_records"]):
            let records = DemoResources.dnsRecords(for: zone)
            return envelope(records, info: ["page": 1, "per_page": 100, "count": records.count, "total_count": records.count, "total_pages": 1])
        case ("POST", ["dns_records"]):
            return envelope(DemoResources.record(from: body ?? [:], id: DemoData.hex(Int.random(in: 1000...999_999))))
        case ("PUT", let path) where path.count == 2 && path[0] == "dns_records":
            return envelope(DemoResources.record(from: body ?? [:], id: path[1]))
        case ("DELETE", let path) where path.count == 2 && path[0] == "dns_records":
            return envelope(["id": path[1]])
        case ("GET", ["workers", "routes"]):
            return envelope(DemoResources.routes(for: zone))
        default:
            return nil
        }
    }

    static func envelope(_ result: Any?, info: [String: Any]? = nil, errors: [[String: Any]] = []) -> [String: Any] {
        var object: [String: Any] = [
            "success": errors.isEmpty,
            "errors": errors,
            "messages": [],
            "result": result ?? NSNull()
        ]
        if let info {
            object["result_info"] = info
        }
        return object
    }
}
