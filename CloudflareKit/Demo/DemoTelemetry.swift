import Foundation

enum DemoTelemetry {
    static var keys: [[String: Any]] {
        let additional = [
            LogQueryKey(key: "$metadata.service", type: .string),
            LogQueryKey(key: "$metadata.duration", type: .number),
            LogQueryKey(key: "$workers.scriptName", type: .string),
            LogQueryKey(key: "source.message", type: .string)
        ]
        return (LogQueryKey.common + additional).map { key in
            ["key": key.key, "type": key.type.rawValue, "lastSeenAt": Date.now.timeIntervalSince1970 * 1000]
        }
    }

    static func values(body: [String: Any]?, scriptName: String?) -> [[String: Any]] {
        guard let key = body?["key"] as? String, let type = body?["type"] as? String else { return [] }
        var seenValues = Set<String>()
        return DemoResources.events(scriptName: scriptName).compactMap { event in
            guard let value = lookup(key, in: event), seenValues.insert("\(value)").inserted else { return nil }
            return ["dataset": "cloudflare-workers", "key": key, "type": type, "value": value]
        }
    }

    static func matching(_ events: [[String: Any]], parameters: [String: Any]?) -> [[String: Any]] {
        let filters = parameters?["filters"] as? [[String: Any]] ?? []
        let needle = (parameters?["needle"] as? [String: Any])?["value"] as? String
        return events.filter { event in
            let passesFilters = filters.allSatisfy { matches(event, filter: $0) }
            guard let needle else { return passesFilters }
            return passesFilters && "\(event)".localizedCaseInsensitiveContains(needle)
        }
    }

    private static func lookup(_ key: String, in event: [String: Any]) -> Any? {
        var current: Any? = event
        for part in key.split(separator: ".") {
            current = (current as? [String: Any])?[String(part)]
        }
        return current
    }

    private static func matches(_ event: [String: Any], filter: [String: Any]) -> Bool {
        guard let key = filter["key"] as? String, let operation = filter["operation"] as? String else { return true }
        let actual = lookup(key, in: event)
        if operation == "exists" { return actual != nil }
        if operation == "is_null" { return actual == nil }
        guard let actual, let expected = filter["value"] else { return operation == "neq" || operation == "not_includes" }
        let actualText = "\(actual)"
        let expectedText = "\(expected)"
        if let actualNumber = actual as? Double ?? (actual as? Int).map(Double.init),
           let expectedNumber = expected as? Double ?? (expected as? Int).map(Double.init) {
            return compare(actualNumber, expectedNumber, operation: operation)
        }
        switch operation {
        case "eq": return actualText == expectedText
        case "neq": return actualText != expectedText
        case "includes": return actualText.contains(expectedText)
        case "not_includes": return !actualText.contains(expectedText)
        case "starts_with": return actualText.hasPrefix(expectedText)
        case "ends_with": return actualText.hasSuffix(expectedText)
        case "regex": return actualText.range(of: expectedText, options: .regularExpression) != nil
        case "in": return expectedText.split(separator: ",").contains { $0 == actualText }
        default: return false
        }
    }

    private static func compare(_ actual: Double, _ expected: Double, operation: String) -> Bool {
        switch operation {
        case "eq": actual == expected
        case "neq": actual != expected
        case "gt": actual > expected
        case "gte": actual >= expected
        case "lt": actual < expected
        case "lte": actual <= expected
        default: false
        }
    }
}
