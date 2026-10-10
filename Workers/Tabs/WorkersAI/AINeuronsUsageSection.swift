import CloudflareKit
import SwiftUI

struct AINeuronsUsageSection: View {
    let client: CloudflareClient
    let account: Account
    let refreshCount: Int
    @AppStorage private var plan: WorkersPlan
    @State private var usage: CachedResource<[AIAnalyticsPoint]>

    init(client: CloudflareClient, account: Account, refreshCount: Int) {
        self.client = client
        self.account = account
        self.refreshCount = refreshCount
        _plan = AppStorage(wrappedValue: .free, "WorkersPlan.\(account.id)")
        _usage = State(initialValue: CachedResource(key: "ai-neurons-\(account.id)-today"))
    }

    var body: some View {
        Section {
            Picker(.morePlanTitle, selection: $plan) {
                ForEach(WorkersPlan.allCases) { plan in
                    Text(plan.title).tag(plan)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(.workersAIUsageToday)
                if let points = usage.value {
                    let used = points.reduce(0) { $0 + $1.neurons }
                    let fraction = min(used / 10_000, 1)
                    ProgressView(value: fraction).tint(fraction >= 0.9 ? .red : .accentColor)
                    Text(.workersAIUsageUsed(used.formatted(.number.precision(.fractionLength(0...1)))))
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text(.workersAIUsageRemaining(max(10_000 - used, 0).formatted(.number.precision(.fractionLength(0...1)))))
                        .font(.subheadline).foregroundStyle(.secondary)
                } else if usage.error == nil {
                    ProgressView()
                }
                if let error = usage.error {
                    Text(error.localizedDescription).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
        } header: {
            Text(.workersAIUsageTitle)
        } footer: {
            Text(plan == .free ? .workersAIUsageFreeFooter : .workersAIUsagePaidFooter)
        }
        .task(id: refreshCount) { await reload() }
    }

    private func reload() async {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        await usage.refresh {
            try await client.aiAnalytics(accountId: account.id, range: .day, since: calendar.startOfDay(for: .now))
        }
    }
}
