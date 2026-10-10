import Foundation

public extension CloudflareClient {
    func requestCount(accountId: String, since start: Date, until end: Date = .now) async throws -> Int {
        async let workers = requestTotal(accountId: accountId, dataset: "workersInvocationsAdaptive", start: start, end: end)
        async let pagesFunctions = try? requestTotal(
            accountId: accountId,
            dataset: "pagesFunctionsInvocationsAdaptiveGroups",
            start: start,
            end: end
        )
        return try await workers + (await pagesFunctions ?? 0)
    }

    private func requestTotal(accountId: String, dataset: String, start: Date, end: Date) async throws -> Int {
        let query = """
        {
          viewer {
            accounts(filter: { accountTag: "\(accountId)" }) {
              \(dataset)(limit: 10000, filter: { datetime_geq: "\(start.formatted(.iso8601))", datetime_leq: "\(end.formatted(.iso8601))" }) {
                sum { requests }
              }
            }
          }
        }
        """
        let data: ViewerData<AccountsViewer<RequestTotalAccount>> = try await graphQL(query)
        let account = data.viewer.accounts.first
        let groups = account?.workersInvocationsAdaptive ?? account?.pagesFunctionsInvocationsAdaptiveGroups ?? []
        return groups.reduce(0) { $0 + $1.sum.requests }
    }
}
