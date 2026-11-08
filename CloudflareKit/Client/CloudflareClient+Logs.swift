import Foundation

public extension CloudflareClient {
    func workerEvents(
        accountId: String,
        scriptName: String,
        matching logQuery: LogQuery = LogQuery(),
        from startDate: Date,
        to endDate: Date,
        limit: Int = 100
    ) async throws -> [ObservabilityEvent] {
        let query = TelemetryQuery(
            queryId: "workers-app-events",
            timeframe: TelemetryQuery.Timeframe(from: startDate, to: endDate),
            view: "events",
            limit: limit,
            parameters: TelemetryQuery.Parameters(
                filters: [.filter(.service(scriptName))] + TelemetryQuery.FilterItem.items(for: logQuery),
                needle: logQuery.searchText.map {
                    TelemetryQuery.Needle(value: $0, isRegex: logQuery.isSearchRegex ? true : nil)
                }
            )
        )
        let body = try JSONEncoder().encode(query)
        let response: TelemetryQueryResponse = try await result(
            .post,
            path: "accounts/\(accountId)/workers/observability/telemetry/query",
            body: body
        )
        return (response.events?.events ?? []).sorted { $0.timestamp > $1.timestamp }
    }

    func workerLogKeys(
        accountId: String,
        scriptName: String,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [LogQueryKey] {
        let timeframe = TelemetryQuery.Timeframe(from: startDate, to: endDate)
        let query = TelemetryKeysQuery(
            filters: [.service(scriptName)],
            from: timeframe.from,
            to: timeframe.to,
            limit: 1000
        )
        return try await result(
            .post,
            path: "accounts/\(accountId)/workers/observability/telemetry/keys",
            body: try JSONEncoder().encode(query)
        )
    }

    func workerLogValues(
        accountId: String,
        scriptName: String,
        key: LogQueryKey,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [LogQueryValue] {
        let query = TelemetryValuesQuery(
            datasets: [],
            key: key.key,
            type: key.type.rawValue,
            timeframe: TelemetryQuery.Timeframe(from: startDate, to: endDate),
            filters: [.service(scriptName)],
            limit: 100
        )
        return try await result(
            .post,
            path: "accounts/\(accountId)/workers/observability/telemetry/values",
            body: try JSONEncoder().encode(query)
        )
    }

    func startTail(accountId: String, scriptName: String) async throws -> WorkerTail {
        try await result(.post, path: "accounts/\(accountId)/workers/scripts/\(scriptName)/tails")
    }

    func deleteTail(accountId: String, scriptName: String, tailId: String) async throws {
        let _: APIEnvelope<JSONValue> = try await send(
            .delete,
            path: "accounts/\(accountId)/workers/scripts/\(scriptName)/tails/\(tailId)"
        )
    }
}
