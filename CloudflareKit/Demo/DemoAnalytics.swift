import Foundation

enum DemoAnalytics {
    static func response(for query: String) -> [String: Any] {
        let isHourly = query.contains("datetimeHour") || query.contains("httpRequests1hGroups")
        let buckets = timeBuckets(start: startDate(in: query), hourly: isHourly)
        let bucketScale = isHourly ? 1.0 : 24.0

        if query.contains("workersInvocationsAdaptive") {
            let filterName = value(after: "scriptName: ", in: query)
            let scripts = DemoData.scripts.filter { filterName == nil || $0.name == filterName }
            let groups = scripts.flatMap { script in
                buckets.enumerated().map { index, date -> [String: Any] in
                    let seed = DemoData.stableHash(script.name) &+ index
                    let requests = Int(script.baseRequests * bucketScale * DemoData.daily(date) * (0.8 + DemoData.noise(seed) * 0.4))
                    let errorSpike = index % 17 == 11 ? 6.0 : 1.0
                    let errors = Int(Double(requests) * script.errorRate * errorSpike * (0.5 + DemoData.noise(seed + 1)))
                    return [
                        "sum": ["requests": requests, "errors": errors, "subrequests": requests * 2 / 3],
                        "quantiles": [
                            "cpuTimeP50": script.cpuTime * (0.85 + DemoData.noise(seed + 2) * 0.3),
                            "cpuTimeP99": script.cpuTime * (3 + DemoData.noise(seed + 3))
                        ],
                        "dimensions": [
                            (isHourly ? "datetimeHour" : "date"): isHourly ? DemoData.iso(date) : day(date),
                            "scriptName": script.name
                        ]
                    ]
                }
            }
            return ["viewer": ["accounts": [["workersInvocationsAdaptive": groups]]]]
        }

        if query.contains("durableObjectsInvocationsAdaptiveGroups") {
            let filterId = value(after: "namespaceId: ", in: query)
            let namespaces = DemoData.namespaces.filter { filterId == nil || $0.id == filterId }
            let groups = namespaces.flatMap { namespace in
                buckets.enumerated().map { index, date -> [String: Any] in
                    let seed = DemoData.stableHash(namespace.id) &+ index
                    let requests = Int(namespace.baseRequests * bucketScale * DemoData.daily(date) * (0.75 + DemoData.noise(seed) * 0.5))
                    return [
                        "sum": ["requests": requests],
                        "dimensions": [
                            (isHourly ? "datetimeHour" : "date"): isHourly ? DemoData.iso(date) : day(date),
                            "namespaceId": namespace.id
                        ]
                    ]
                }
            }
            return ["viewer": ["accounts": [["durableObjectsInvocationsAdaptiveGroups": groups]]]]
        }

        if query.contains("httpRequestsAdaptiveGroups") {
            let zones = DemoData.zones.filter { zoneTags(in: query).contains($0.id) }.map { zone -> [String: Any] in
                let groups = buckets.enumerated().flatMap { index, date -> [[String: Any]] in
                    let seed = DemoData.stableHash(zone.id) &+ index
                    let requests = zone.baseRequests * bucketScale * DemoData.daily(date) * (0.8 + DemoData.noise(seed) * 0.4)
                    let timeKey = isHourly ? "datetimeHour" : "date"
                    let timeValue = isHourly ? DemoData.iso(date) : day(date)
                    return [
                        ("managed_challenge", 0, requests * 0.04 * DemoData.noise(seed + 3)),
                        ("unknown", 0, requests * (0.55 + DemoData.noise(seed + 1) * 0.25)),
                        ("unknown", 200, requests * 0.3)
                    ].map { action, status, count in
                        [
                            "count": Int(count),
                            "dimensions": [timeKey: timeValue, "securityAction": action, "originResponseStatus": status]
                        ]
                    }
                }
                return ["zoneTag": zone.id, "httpRequestsAdaptiveGroups": groups]
            }
            return ["viewer": ["zones": zones]]
        }

        let zoneIds = zoneTags(in: query)
        let groupsKey = isHourly ? "httpRequests1hGroups" : "httpRequests1dGroups"
        let zones = DemoData.zones.filter { zoneIds.contains($0.id) }.map { zone -> [String: Any] in
            let groups = buckets.enumerated().map { index, date -> [String: Any] in
                let seed = DemoData.stableHash(zone.id) &+ index
                let requests = Int(zone.baseRequests * bucketScale * DemoData.daily(date) * (0.8 + DemoData.noise(seed) * 0.4))
                let cachedRequests = Int(Double(requests) * (0.55 + DemoData.noise(seed + 1) * 0.25))
                let bytes = requests * (38_000 + Int(DemoData.noise(seed + 2) * 20_000))
                return [
                    "dimensions": [(isHourly ? "datetime" : "date"): isHourly ? DemoData.iso(date) : day(date)],
                    "sum": [
                        "requests": requests,
                        "cachedRequests": cachedRequests,
                        "bytes": bytes,
                        "cachedBytes": bytes * 6 / 10,
                        "threats": Int(Double(requests) * 0.002 * DemoData.noise(seed + 3)),
                        "pageViews": requests / 4
                    ],
                    "uniq": ["uniques": max(1, requests / 9)]
                ]
            }
            return ["zoneTag": zone.id, groupsKey: groups]
        }
        return ["viewer": ["zones": zones]]
    }

    private static func timeBuckets(start: Date, hourly: Bool) -> [Date] {
        let calendar = Calendar(identifier: .gregorian)
        let component: Calendar.Component = hourly ? .hour : .day
        var date = calendar.dateInterval(of: component, for: start)?.start ?? start
        var dates: [Date] = []
        while date <= .now {
            dates.append(date)
            date = calendar.date(byAdding: component, value: 1, to: date) ?? .now.addingTimeInterval(1)
        }
        return dates
    }

    private static func startDate(in query: String) -> Date {
        for marker in ["datetime_geq: ", "datetimeHour_geq: ", "date_geq: "] {
            if let text = value(after: marker, in: query), let date = CloudflareJSON.parseDate(text) {
                return date
            }
        }
        return .now.addingTimeInterval(-24 * 3600)
    }

    private static func value(after marker: String, in query: String) -> String? {
        guard let range = query.range(of: marker + "\"") else { return nil }
        let rest = query[range.upperBound...]
        guard let end = rest.firstIndex(of: "\"") else { return nil }
        return String(rest[..<end])
    }

    private static func zoneTags(in query: String) -> [String] {
        guard let start = query.range(of: "zoneTag_in: ["),
              let end = query[start.upperBound...].firstIndex(of: "]") else { return [] }
        return query[start.upperBound..<end]
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " \"")) }
    }

    private static func day(_ date: Date) -> String {
        date.formatted(.iso8601.year().month().day())
    }
}
