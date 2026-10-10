import CloudflareKit
import SwiftUI

struct WorkersUsageSection: View {
    let client: CloudflareClient
    let account: Account
    let tokenName: String?

    @AppStorage private var plan: WorkersPlan
    @State private var freeUsage: CachedResource<Int>
    @State private var paidUsage: CachedResource<Int>

    init(client: CloudflareClient, account: Account, tokenName: String?) {
        self.client = client
        self.account = account
        self.tokenName = tokenName
        _plan = AppStorage(wrappedValue: .free, "WorkersPlan.\(account.id)")
        _freeUsage = State(initialValue: CachedResource(key: "usage-\(account.id)-free"))
        _paidUsage = State(initialValue: CachedResource(key: "usage-\(account.id)-paid"))
    }

    private var usage: CachedResource<Int> {
        plan == .free ? freeUsage : paidUsage
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.headline)
                if let tokenName, tokenName != account.name {
                    Text(tokenName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Picker(.morePlanTitle, selection: $plan) {
                ForEach(WorkersPlan.allCases) { plan in
                    Text(plan.title).tag(plan)
                }
            }
            usageRow
        } header: {
            Text(.workersUsageTitle)
        } footer: {
            Text(plan == .free ? .moreUsageFreeFooter : .moreUsagePaidFooter)
        }
        .task(id: plan) {
            let start = plan.periodStart()
            await usage.refresh {
                try await client.requestCount(accountId: account.id, since: start)
            }
        }
    }

    private var usageRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(plan == .free ? .moreUsageToday : .moreUsageMonth)
            if let used = usage.value {
                let limit = plan.includedRequests
                let fraction = min(Double(used) / Double(limit), 1)
                ProgressView(value: fraction)
                    .tint(fraction >= 0.9 ? .red : .accentColor)
                Text(.moreUsageRemaining(max(limit - used, 0).formatted(), limit.formatted()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let error = usage.error {
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 2)
    }
}
