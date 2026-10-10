import Foundation

enum DemoResources {
    static func script(_ script: DemoData.Script) -> [String: Any] {
        [
            "id": script.name,
            "created_on": DemoData.ago(hours: script.modifiedHoursAgo + 24 * 90),
            "modified_on": DemoData.ago(hours: script.modifiedHoursAgo),
            "usage_model": "standard",
            "handlers": script.handlers,
            "compatibility_date": "2026-09-01",
            "compatibility_flags": ["nodejs_compat"],
            "last_deployed_from": "wrangler",
            "has_modules": true,
            "logpush": false
        ]
    }

    static func zone(_ zone: DemoData.DemoZone) -> [String: Any] {
        let index = DemoData.zones.firstIndex { $0.id == zone.id } ?? 0
        var object: [String: Any] = [
            "id": zone.id,
            "name": zone.name,
            "status": zone.status,
            "paused": false,
            "type": "full",
            "development_mode": 0,
            "name_servers": ["ines.ns.cloudflare.invalid", "rudy.ns.cloudflare.invalid"],
            "original_name_servers": ["ns1.kaiser-corporation.invalid", "ns2.kaiser-corporation.invalid"],
            "original_registrar": "Kaiser Corporation",
            "plan": ["id": DemoData.hex(index + 300), "name": zone.plan],
            "account": ["id": DemoData.accountId, "name": "Kivotos Cloud"],
            "created_on": DemoData.ago(hours: Double(24 * (200 + index * 90))),
            "modified_on": DemoData.ago(hours: 48)
        ]
        if zone.status == "active" {
            object["activated_on"] = DemoData.ago(hours: Double(24 * (199 + index * 90)))
        }
        return object
    }

    static func dnsRecords(for zone: DemoData.DemoZone) -> [[String: Any]] {
        let name = zone.name
        let entries: [(String, String, String, Bool, Int?, String?)] = [
            ("A", name, "312.405.388.24", true, nil, "Origin load balancer"),
            ("AAAA", name, "2001:db8:4860::24", true, nil, nil),
            ("CNAME", "www.\(name)", name, true, nil, nil),
            ("CNAME", "api.\(name)", "schale-gateway.kivotos.workers.invalid", true, nil, "Routed to Workers"),
            ("CNAME", "images.\(name)", "momotalk-compress.kivotos.workers.invalid", true, nil, nil),
            ("A", "status.\(name)", "471.333.420.7", false, nil, nil),
            ("MX", name, "route1.mx.cloudflare.invalid", false, 12, nil),
            ("MX", name, "route2.mx.cloudflare.invalid", false, 54, nil),
            ("TXT", name, "v=spf1 include:_spf.mx.cloudflare.invalid ~all", false, nil, nil),
            ("TXT", "_dmarc.\(name)", "v=DMARC1; p=quarantine; rua=mailto:dmarc@\(name)", false, nil, nil),
            ("CAA", name, "0 issue \"veritas.millenium.edu.kv\"", false, nil, nil)
        ]
        return entries.enumerated().map { index, entry in
            var object: [String: Any] = [
                "id": DemoData.hex(DemoData.stableHash(name) &+ index),
                "type": entry.0,
                "name": entry.1,
                "content": entry.2,
                "proxied": entry.3,
                "proxiable": ["A", "AAAA", "CNAME"].contains(entry.0),
                "ttl": entry.3 ? 1 : 3600,
                "created_on": DemoData.ago(hours: Double(24 * (30 + index * 7))),
                "modified_on": DemoData.ago(hours: Double(24 * (2 + index)))
            ]
            if let priority = entry.4 { object["priority"] = priority }
            if let comment = entry.5 { object["comment"] = comment }
            return object
        }
    }

    static func record(from body: [String: Any], id: String) -> [String: Any] {
        var object = body
        object["id"] = id
        object["proxiable"] = ["A", "AAAA", "CNAME"].contains(body["type"] as? String ?? "")
        object["created_on"] = DemoData.iso(.now)
        object["modified_on"] = DemoData.iso(.now)
        if object["ttl"] == nil { object["ttl"] = 1 }
        return object
    }

    static func routes(for zone: DemoData.DemoZone) -> [[String: Any]] {
        guard zone.status == "active" else { return [] }
        return [
            ["id": DemoData.hex(zone.name.count + 400), "pattern": "api.\(zone.name)/*", "script": "schale-gateway"],
            ["id": DemoData.hex(zone.name.count + 401), "pattern": "\(zone.name)/auth/*", "script": "momotalk-auth"],
            ["id": DemoData.hex(zone.name.count + 402), "pattern": "\(zone.name)/static/*", "script": NSNull()]
        ]
    }

    static var customDomains: [[String: Any]] { [
        ["id": DemoData.hex(500), "hostname": "images.schale.gov.kv", "service": "momotalk-compress", "environment": "production", "zone_id": DemoData.zones[0].id, "zone_name": "schale.gov.kv"],
        ["id": DemoData.hex(501), "hostname": "chat.momotalk.kv", "service": "momotalk-chats", "environment": "production", "zone_id": DemoData.zones[1].id, "zone_name": "momotalk.kv"],
        ["id": DemoData.hex(502), "hostname": "hooks.millenium.edu.kv", "service": "memorial-stream", "environment": "production", "zone_id": DemoData.zones[2].id, "zone_name": "millenium.edu.kv"]
    ] }

    static func namespace(_ namespace: DemoData.Namespace) -> [String: Any] {
        [
            "id": namespace.id,
            "name": "\(namespace.script)_\(namespace.className)",
            "script": namespace.script,
            "class": namespace.className,
            "use_sqlite": namespace.sqlite
        ]
    }

    static func objects(namespaceId: String, cursor: String?) -> [String: Any] {
        let count = DemoData.namespaces.first { $0.id == namespaceId }?.objectCount ?? 0
        let pageSize = 25
        let start = Int(cursor ?? "0") ?? 0
        let end = min(start + pageSize, count)
        let objects = (start..<max(start, end)).map { index in
            ["id": DemoData.hex(DemoData.stableHash(namespaceId) &+ index, length: 64), "hasStoredData": true] as [String: Any]
        }
        let nextCursor = end < count ? String(end) : ""
        return DemoRouter.envelope(objects, info: ["count": objects.count, "cursor": nextCursor])
    }

    static func deployments(for script: DemoData.Script) -> [[String: Any]] {
        let messages = ["Add rate limiting to /v2 endpoints", "Gradual rollout of new cache keys", "Fix CORS preflight handling", "Upgrade compatibility date", "Initial deployment"]
        return messages.enumerated().map { index, message in
            let hours = script.modifiedHoursAgo + Double(index * index) * 26
            var versions: [[String: Any]] = [["version_id": DemoData.hex(script.name.count * 10 + index), "percentage": 100]]
            if index == 1 {
                versions = [
                    ["version_id": DemoData.hex(script.name.count * 10 + index), "percentage": 90],
                    ["version_id": DemoData.hex(script.name.count * 10 + index + 1), "percentage": 10]
                ]
            }
            return [
                "id": DemoData.hex(script.name.count * 100 + index),
                "created_on": DemoData.ago(hours: hours),
                "source": index == 3 ? "dash" : "wrangler",
                "strategy": "percentage",
                "author_email": index == 3 ? "yuuka@millenium.edu.kv" : "sensei@schale.gov.kv",
                "annotations": ["workers/message": message, "workers/triggered_by": "deployment"],
                "versions": versions
            ]
        }
    }

    static func versions(for script: DemoData.Script) -> [[String: Any]] {
        let tags = ["v2.4.1", "v2.4.0", "v2.3.2", "v2.3.1", "v2.3.0", "v2.2.0"]
        return tags.enumerated().map { index, tag in
            let hours = script.modifiedHoursAgo + Double(index * index) * 20
            return [
                "id": DemoData.hex(script.name.count * 10 + index),
                "number": tags.count - index + 18,
                "metadata": [
                    "created_on": DemoData.ago(hours: hours),
                    "modified_on": DemoData.ago(hours: hours),
                    "author_email": "sensei@schale.gov.kv",
                    "source": "wrangler",
                    "has_preview": true
                ],
                "annotations": ["workers/tag": tag, "workers/message": index == 0 ? "Tighten request validation" : "Routine update"]
            ]
        }
    }

    static func settings(for script: DemoData.Script) -> [String: Any] {
        var bindings: [[String: Any]] = [
            ["name": "ENVIRONMENT", "type": "plain_text", "text": "production"],
            ["name": "API_SECRET", "type": "secret_text"],
            ["name": "CACHE", "type": "kv_namespace", "namespace_id": DemoData.hex(900)],
            ["name": "ANALYTICS", "type": "analytics_engine", "dataset": "\(script.name)_events"]
        ]
        for namespace in DemoData.namespaces where namespace.script == script.name {
            bindings.append(["name": namespace.className.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1_$2", options: .regularExpression).uppercased(), "type": "durable_object_namespace", "class_name": namespace.className, "script_name": namespace.script])
        }
        if script.name == "momotalk-compress" {
            bindings.append(["name": "IMAGES", "type": "r2_bucket", "bucket_name": "originals"])
        }
        if script.name == "momotalk-auth" {
            bindings.append(["name": "DB", "type": "d1", "id": DemoData.hex(901)])
        }
        if script.name == "memorial-stream" {
            bindings.append(["name": "OUTBOX", "type": "queue", "queue_name": "webhook-outbox"])
            bindings.append(["name": "AUTH", "type": "service", "service": "momotalk-auth", "environment": "production"])
        }
        return [
            "bindings": bindings,
            "compatibility_date": "2026-09-01",
            "compatibility_flags": ["nodejs_compat"],
            "usage_model": "standard",
            "logpush": false,
            "observability": ["enabled": true, "head_sampling_rate": 1],
            "placement": ["mode": "smart"]
        ]
    }

    static func schedules(for script: DemoData.Script) -> [[String: Any]] {
        guard script.handlers.contains("scheduled") else { return [] }
        return [
            ["cron": "*/30 * * * *", "created_on": DemoData.ago(hours: 900), "modified_on": DemoData.ago(hours: 900)],
            ["cron": "0 3 * * *", "created_on": DemoData.ago(hours: 900), "modified_on": DemoData.ago(hours: 900)]
        ]
    }

    static func events(scriptName: String?) -> [[String: Any]] {
        let scriptNames = scriptName.map { [$0] } ?? DemoData.scripts.map(\.name)
        let spacing: Double = scriptName == "wildhunt-visitor-management" ? 1800 : 47
        return (0..<60).map { index in
            let name = scriptNames[index % scriptNames.count]
            let event = DemoTraffic.event(scriptName: name, index: index / scriptNames.count)
            let timestamp = Date.now.addingTimeInterval(-Double(index) * spacing - DemoData.noise(index) * 30)
            var metadata: [String: Any] = [
                "id": DemoData.hex(index + 7000),
                "service": name,
                "trigger": event.trigger,
                "level": event.level,
                "message": event.summary,
                "duration": 12 + DemoData.noise(index) * 80
            ]
            if let status = event.status { metadata["statusCode"] = status }
            if let url = event.url { metadata["url"] = url }
            if let exception = event.exception { metadata["error"] = "\(exception.name): \(exception.message)" }
            return [
                "$metadata": metadata,
                "timestamp": timestamp.timeIntervalSince1970 * 1000,
                "dataset": "cloudflare-workers",
                "source": ["message": event.summary, "logs": event.logs.map(\.message)],
                "$workers": [
                    "eventType": event.eventType,
                    "scriptName": name,
                    "outcome": event.exception == nil ? "ok" : "exception",
                    "cpuTimeMs": 1 + DemoData.noise(index + 3) * 8,
                    "wallTimeMs": 10 + DemoData.noise(index + 5) * 90,
                    "requestId": DemoData.hex(index + 8000, length: 16)
                ]
            ]
        }
    }
}
