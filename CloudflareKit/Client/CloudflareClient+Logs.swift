import Foundation

public extension CloudflareClient {
    func workerEvents(
        accountId: String,
        scriptName: String,
        from startDate: Date,
        to endDate: Date,
        limit: Int = 100
    ) async throws -> [ObservabilityEvent] {
        let query = TelemetryQuery(
            queryId: "workers-app-events",
            timeframe: TelemetryQuery.Timeframe(
                from: Int(startDate.timeIntervalSince1970 * 1000),
                to: Int(endDate.timeIntervalSince1970 * 1000)
            ),
            view: "events",
            limit: limit,
            parameters: TelemetryQuery.Parameters(
                filters: [
                    TelemetryQuery.Filter(key: "$metadata.service", operation: "eq", type: "string", value: scriptName)
                ]
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
