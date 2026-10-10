import Foundation

public extension CloudflareClient {
    func workerAnalytics(
        accountId: String,
        range: AnalyticsRange,
        scriptName: String? = nil
    ) async throws -> [WorkerAnalyticsPoint] {
        let interval = range.interval()
        let timeDimension = range.usesHourlyBuckets ? "datetimeHour" : "date"
        var filter = "datetime_geq: \(literal(timestamp(interval.start))), datetime_leq: \(literal(timestamp(interval.end)))"
        if let scriptName {
            filter += ", scriptName: \(literal(scriptName))"
        }
        let query = """
        {
          viewer {
            accounts(filter: { accountTag: \(literal(accountId)) }) {
              workersInvocationsAdaptive(limit: 10000, filter: { \(filter) }, orderBy: [\(timeDimension)_ASC]) {
                sum { requests errors subrequests }
                quantiles { cpuTimeP50 cpuTimeP99 }
                dimensions { \(timeDimension) scriptName }
              }
            }
          }
        }
        """
        let data: ViewerData<AccountsViewer<WorkerInvocationsAccount>> = try await graphQL(query)
        let groups = data.viewer.accounts.first?.workersInvocationsAdaptive ?? []
        return groups.compactMap { group in
            guard let date = group.dimensions.datetimeHour ?? group.dimensions.date else { return nil }
            return WorkerAnalyticsPoint(
                date: date,
                scriptName: group.dimensions.scriptName,
                requests: group.sum.requests,
                errors: group.sum.errors,
                subrequests: group.sum.subrequests,
                cpuTimeP50: group.quantiles.cpuTimeP50,
                cpuTimeP99: group.quantiles.cpuTimeP99
            )
        }
    }

    func zoneAnalytics(zoneIds: [String], range: AnalyticsRange) async throws -> [ZoneAnalyticsPoint] {
        guard !zoneIds.isEmpty else { return [] }
        let interval = range.interval()
        let zoneList = zoneIds.map(literal).joined(separator: ", ")
        let groupsQuery: String
        if range == .day {
            groupsQuery = """
            httpRequests1hGroups(limit: 1000, filter: { datetime_geq: \(literal(timestamp(interval.start))), datetime_lt: \(literal(timestamp(interval.end))) }, orderBy: [datetime_ASC]) {
              dimensions { datetime }
              sum { requests cachedRequests bytes cachedBytes threats pageViews }
              uniq { uniques }
            }
            """
        } else {
            groupsQuery = """
            httpRequests1dGroups(limit: 1000, filter: { date_geq: \(literal(day(interval.start))), date_leq: \(literal(day(interval.end))) }, orderBy: [date_ASC]) {
              dimensions { date }
              sum { requests cachedRequests bytes cachedBytes threats pageViews }
              uniq { uniques }
            }
            """
        }
        let query = """
        {
          viewer {
            zones(filter: { zoneTag_in: [\(zoneList)] }) {
              zoneTag
              \(groupsQuery)
            }
          }
        }
        """
        let data: ViewerData<ZonesViewer<ZoneTrafficData>> = try await graphQL(query)
        return data.viewer.zones.flatMap { zone in
            (zone.httpRequests1hGroups ?? zone.httpRequests1dGroups ?? []).compactMap { group in
                guard let date = group.dimensions.datetime ?? group.dimensions.date else { return nil }
                return ZoneAnalyticsPoint(
                    date: date,
                    zoneId: zone.zoneTag,
                    requests: group.sum.requests,
                    cachedRequests: group.sum.cachedRequests,
                    bytes: group.sum.bytes,
                    cachedBytes: group.sum.cachedBytes,
                    threats: group.sum.threats,
                    pageViews: group.sum.pageViews,
                    uniqueVisitors: group.uniq.uniques
                )
            }
        }
    }

    func zoneRequestOutcomes(zoneId: String, range: AnalyticsRange) async throws -> [ZoneOutcomePoint] {
        let interval = range.interval()
        let timeDimension = range.usesHourlyBuckets ? "datetimeHour" : "date"
        let query = """
        {
          viewer {
            zones(filter: { zoneTag_in: [\(literal(zoneId))] }) {
              httpRequestsAdaptiveGroups(limit: 10000, filter: { datetime_geq: \(literal(timestamp(interval.start))), datetime_lt: \(literal(timestamp(interval.end))), requestSource: "eyeball" }, orderBy: [\(timeDimension)_ASC]) {
                count
                dimensions { \(timeDimension) securityAction originResponseStatus }
              }
            }
          }
        }
        """
        let data: ViewerData<ZonesViewer<ZoneOutcomesData>> = try await graphQL(query)
        var totals: [Date: (mitigated: Int, servedByCloudflare: Int, servedByOrigin: Int)] = [:]
        for group in data.viewer.zones.first?.httpRequestsAdaptiveGroups ?? [] {
            guard let date = group.dimensions.datetimeHour ?? group.dimensions.date else { continue }
            var total = totals[date] ?? (0, 0, 0)
            if Self.mitigatingActions.contains(group.dimensions.securityAction ?? "") {
                total.mitigated += group.count
            } else if (group.dimensions.originResponseStatus ?? 0) > 0 {
                total.servedByOrigin += group.count
            } else {
                total.servedByCloudflare += group.count
            }
            totals[date] = total
        }
        return totals
            .map { ZoneOutcomePoint(date: $0.key, mitigated: $0.value.mitigated, servedByCloudflare: $0.value.servedByCloudflare, servedByOrigin: $0.value.servedByOrigin) }
            .sorted { $0.date < $1.date }
    }

    private static let mitigatingActions: Set<String> = [
        "block", "challenge", "jschallenge", "managed_challenge", "connection_close", "force_connection_close"
    ]

    func durableObjectAnalytics(
        accountId: String,
        range: AnalyticsRange,
        namespaceId: String? = nil
    ) async throws -> [DurableObjectAnalyticsPoint] {
        let interval = range.interval()
        let timeDimension = range.usesHourlyBuckets ? "datetimeHour" : "date"
        var filter: String
        if range.usesHourlyBuckets {
            filter = "datetimeHour_geq: \(literal(timestamp(interval.start))), datetimeHour_leq: \(literal(timestamp(interval.end)))"
        } else {
            filter = "date_geq: \(literal(day(interval.start))), date_leq: \(literal(day(interval.end)))"
        }
        if let namespaceId {
            filter += ", namespaceId: \(literal(namespaceId))"
        }
        let query = """
        {
          viewer {
            accounts(filter: { accountTag: \(literal(accountId)) }) {
              durableObjectsInvocationsAdaptiveGroups(limit: 10000, filter: { \(filter) }, orderBy: [\(timeDimension)_ASC]) {
                sum { requests }
                dimensions { \(timeDimension) namespaceId }
              }
            }
          }
        }
        """
        let data: ViewerData<AccountsViewer<DurableObjectInvocationsAccount>> = try await graphQL(query)
        let groups = data.viewer.accounts.first?.durableObjectsInvocationsAdaptiveGroups ?? []
        return groups.compactMap { group in
            guard let date = group.dimensions.datetimeHour ?? group.dimensions.date else { return nil }
            return DurableObjectAnalyticsPoint(
                date: date,
                namespaceId: group.dimensions.namespaceId,
                requests: group.sum.requests
            )
        }
    }
}

extension CloudflareClient {
    func graphQL<DataType: Decodable>(_ query: String) async throws -> DataType {
        var request = try makeRequest(.post, path: "graphql", body: try JSONEncoder().encode(GraphQLRequest(query: query)))
        request.timeoutInterval = 30
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudflareError.invalidResponse
        }
        if [401, 403].contains(httpResponse.statusCode) {
            throw CloudflareError.http(statusCode: httpResponse.statusCode)
        }
        let decoded = try? CloudflareJSON.makeDecoder().decode(GraphQLResponse<DataType>.self, from: data)
        if let errors = decoded?.errors, !errors.isEmpty {
            throw CloudflareError.graphQL(messages: errors.map(\.message))
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw CloudflareError.http(statusCode: httpResponse.statusCode)
        }
        if let result = decoded?.data {
            return result
        }
        let strict = try CloudflareJSON.makeDecoder().decode(GraphQLResponse<DataType>.self, from: data)
        guard let result = strict.data else { throw CloudflareError.invalidResponse }
        return result
    }

    func literal(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    func timestamp(_ date: Date) -> String {
        date.formatted(.iso8601)
    }

    private func day(_ date: Date) -> String {
        date.formatted(.iso8601.year().month().day())
    }
}
