import Foundation

// Usage: swift Assets/Scripts/ZoneOutcomesProbe.swift
// Reads CLOUDFLARE_API_TOKEN and CLOUDFLARE_ZONE_ID from .env next to this script.
// Optional: PROBE_DAYS (default 7) to match the dashboard time range.

let scriptDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

func loadEnvironment() -> [String: String] {
    let fileURL = scriptDirectory.appendingPathComponent(".env")
    guard let contents = try? String(contentsOf: fileURL, encoding: .utf8) else {
        print("Missing \(fileURL.path)")
        exit(1)
    }
    var values: [String: String] = [:]
    for line in contents.split(whereSeparator: \.isNewline) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("#"), let separator = trimmed.firstIndex(of: "=") else { continue }
        let key = trimmed[..<separator].trimmingCharacters(in: .whitespaces)
        let value = trimmed[trimmed.index(after: separator)...]
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        values[key] = value
    }
    return values
}

let environment = loadEnvironment()
guard let token = environment["CLOUDFLARE_API_TOKEN"], !token.isEmpty,
      let zoneId = environment["CLOUDFLARE_ZONE_ID"], !zoneId.isEmpty else {
    print("Set CLOUDFLARE_API_TOKEN and CLOUDFLARE_ZONE_ID in .env")
    exit(1)
}
let days = Int(environment["PROBE_DAYS"] ?? "") ?? 7

func graphQL(_ query: String) async throws -> [String: Any] {
    var request = URLRequest(url: URL(string: "https://api.cloudflare.com/client/v4/graphql")!)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query])
    let (data, _) = try await URLSession.shared.data(for: request)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    if let errors = object["errors"] as? [[String: Any]], !errors.isEmpty {
        print("GraphQL errors: \(errors.map { $0["message"] ?? $0 })")
    }
    return object["data"] as? [String: Any] ?? [:]
}

func section(_ title: String) {
    print("\n== \(title) ==")
}

// 1. Discover which dimensions exist on httpRequestsAdaptiveGroups.
section("Dimension types")
let schema = try await graphQL("{ __schema { types { name fields { name } } } }")
let types = ((schema["__schema"] as? [String: Any])?["types"] as? [[String: Any]]) ?? []
let dimensionTypes = types.filter {
    ($0["name"] as? String)?.range(of: "HttpRequestsAdaptiveGroupsDimensions", options: .caseInsensitive) != nil
}
var availableDimensions: Set<String> = []
let interestingWords = ["security", "origin", "cache", "source", "status", "mitigat", "served", "outcome"]
for type in dimensionTypes {
    let names = ((type["fields"] as? [[String: Any]]) ?? []).compactMap { $0["name"] as? String }
    availableDimensions.formUnion(names)
    print("\(type["name"] ?? ""):")
    print("  relevant: \(names.filter { name in interestingWords.contains { name.lowercased().contains($0) } }.sorted())")
}

// 2. Plan limits for this zone.
section("Settings")
let settings = try await graphQL("""
{ viewer { zones(filter: { zoneTag: "\(zoneId)" }) { settings { httpRequestsAdaptiveGroups { enabled maxDuration notOlderThan maxPageSize } } } } }
""")
let zoneSettings = (((settings["viewer"] as? [String: Any])?["zones"] as? [[String: Any]])?.first?["settings"] as? [String: Any])?["httpRequestsAdaptiveGroups"] as? [String: Any]
print(zoneSettings ?? "unavailable")
let maxDuration = (zoneSettings?["maxDuration"] as? Int) ?? 86_400

// 3. Group requests by the candidate dimensions over the dashboard range, chunked to maxDuration.
let candidates = ["securityAction", "securitySource", "cacheStatus", "originResponseStatus", "requestSource", "edgeResponseStatus"]
let dimensions = candidates.filter { availableDimensions.contains($0) }
section("Grouping by \(dimensions)")
guard !dimensions.isEmpty else {
    print("None of \(candidates) exist; check the relevant fields above.")
    exit(0)
}

let formatter = ISO8601DateFormatter()
let endDate = Date()
let startDate = endDate.addingTimeInterval(-Double(days) * 86_400)
var combinationCounts: [String: Int] = [:]
var chunkStart = startDate
while chunkStart < endDate {
    let chunkEnd = min(chunkStart.addingTimeInterval(Double(maxDuration)), endDate)
    let data = try await graphQL("""
    { viewer { zones(filter: { zoneTag: "\(zoneId)" }) { httpRequestsAdaptiveGroups(limit: 10000, filter: { datetime_geq: "\(formatter.string(from: chunkStart))", datetime_lt: "\(formatter.string(from: chunkEnd))" }) { count dimensions { \(dimensions.joined(separator: " ")) } } } } }
    """)
    let groups = ((data["viewer"] as? [String: Any])?["zones"] as? [[String: Any]])?.first?["httpRequestsAdaptiveGroups"] as? [[String: Any]] ?? []
    for group in groups {
        let values = group["dimensions"] as? [String: Any] ?? [:]
        let key = dimensions.map { "\($0)=\(values[$0] ?? "nil")" }.joined(separator: " ")
        combinationCounts[key, default: 0] += group["count"] as? Int ?? 0
    }
    chunkStart = chunkEnd
}

for (key, count) in combinationCounts.sorted(by: { $0.value > $1.value }) {
    print("\(count)\t\(key)")
}
print("Total: \(combinationCounts.values.reduce(0, +)) over \(days) days")
