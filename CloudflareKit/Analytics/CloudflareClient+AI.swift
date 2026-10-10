import Foundation

public extension CloudflareClient {
    func aiAnalytics(accountId: String, range: AnalyticsRange, modelId: String? = nil, since start: Date? = nil) async throws -> [AIAnalyticsPoint] {
        let interval = range.interval()
        let timeDimension = range.usesHourlyBuckets ? "datetimeHour" : "date"
        var filter = "datetime_geq: \(literal(timestamp(start ?? interval.start))), datetime_lt: \(literal(timestamp(interval.end)))"
        if let modelId {
            filter += ", modelId: \(literal(modelId))"
        }
        let query = """
        {
          viewer {
            accounts(filter: { accountTag: \(literal(accountId)) }) {
              aiInferenceAdaptiveGroups(limit: 10000, filter: { \(filter) }, orderBy: [\(timeDimension)_ASC]) {
                count
                sum { totalNeurons totalInputTokens totalOutputTokens totalInferenceTimeMs }
                dimensions { \(timeDimension) modelId errorCode }
              }
            }
          }
        }
        """
        let data: ViewerData<AccountsViewer<AIInferenceAccount>> = try await graphQL(query)
        return (data.viewer.accounts.first?.aiInferenceAdaptiveGroups ?? []).compactMap { group in
            guard let date = group.dimensions.datetimeHour ?? group.dimensions.date else { return nil }
            return AIAnalyticsPoint(
                date: date, modelId: group.dimensions.modelId, requests: group.count,
                errors: group.dimensions.errorCode == 0 ? 0 : group.count,
                neurons: group.sum.totalNeurons, inputTokens: group.sum.totalInputTokens,
                outputTokens: group.sum.totalOutputTokens, inferenceTimeMilliseconds: group.sum.totalInferenceTimeMs
            )
        }
    }
}
