import CloudflareKit
import SwiftUI

struct WorkersAIView: View {
    let resources: AccountResources
    @Environment(CloudflareSession.self) private var session
    @State private var analytics: CachedResource<[AIAnalyticsPoint]>
    @State private var refreshCount = 0
    @State private var range: AnalyticsRange = .week

    init(resources: AccountResources) {
        self.resources = resources
        _analytics = State(initialValue: CachedResource(key: "ai-models-\(resources.accountId)-week"))
    }

    private var modelIds: [String] {
        Array(Set((analytics.value ?? []).filter { $0.requests > 0 }.map(\.modelId))).sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                if let account = session.selectedAccount {
                    AINeuronsUsageSection(client: resources.client, account: account,
                        refreshCount: refreshCount)
                }
                Section {
                    AnalyticsRangePicker(range: $range)
                    AnalyticsSectionStatus(resource: analytics)
                    if let error = analytics.error, analytics.value != nil {
                        Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.secondary)
                    }
                    if analytics.value != nil, modelIds.isEmpty {
                        Text(.workersAIModelsEmpty).foregroundStyle(.secondary)
                    }
                    ForEach(modelIds, id: \.self) { modelId in
                        NavigationLink {
                            AIModelDetailView(client: resources.client, accountId: resources.accountId, modelId: modelId)
                        } label: {
                            AIModelRow(modelId: modelId, requests: (analytics.value ?? [])
                                .filter { $0.modelId == modelId }.reduce(0) { $0 + $1.requests })
                        }
                    }
                } header: {
                    Text(.workersAIModelsTitle)
                } footer: {
                    Text(.workersAIModelsFooter)
                }
            }
            .navigationTitle(.tabsWorkersAI)
            .accountToolbar()
            .task(id: range) {
                analytics = CachedResource(key: "ai-models-\(resources.accountId)-\(range.rawValue)")
                await reload()
            }
            .refreshable {
                refreshCount += 1
                await reload()
            }
        }
    }

    private func reload() async {
        await analytics.refresh {
            try await resources.client.aiAnalytics(accountId: resources.accountId, range: range)
        }
    }
}
