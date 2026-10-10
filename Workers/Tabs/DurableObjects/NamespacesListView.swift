import CloudflareKit
import SwiftUI

struct NamespacesListView: View {
    let client: CloudflareClient
    let accountId: String

    @State private var namespaces: CachedResource<[DurableObjectNamespace]>
    @State private var analytics: CachedResource<[DurableObjectAnalyticsPoint]>
    @State private var searchText = ""

    init(client: CloudflareClient, accountId: String) {
        self.client = client
        self.accountId = accountId
        _namespaces = State(initialValue: CachedResource(key: "do-namespaces-\(accountId)"))
        _analytics = State(initialValue: CachedResource(key: "do-analytics-\(accountId)-day"))
    }

    private var groupedNamespaces: [(String, [DurableObjectNamespace])] {
        let filtered = (namespaces.value ?? []).filter {
            searchText.isEmpty
                || $0.displayName.localizedCaseInsensitiveContains(searchText)
                || ($0.script ?? "").localizedCaseInsensitiveContains(searchText)
        }
        return Dictionary(grouping: filtered) { $0.script ?? String(localized: .sharedOther) }
            .map { ($0.key, $0.value.sorted { $0.displayName < $1.displayName }) }
            .sorted { $0.0 < $1.0 }
    }

    private var requestCounts: [String: Int] {
        (analytics.value ?? []).reduce(into: [:]) { counts, point in
            counts[point.namespaceId, default: 0] += point.requests
        }
    }

    var body: some View {
        NavigationStack {
            List {
                RefreshErrorSection(resource: namespaces)
                ForEach(groupedNamespaces, id: \.0) { scriptName, items in
                    Section(scriptName) {
                        ForEach(items) { namespace in
                            NavigationLink(value: namespace) {
                                NamespaceRow(namespace: namespace, requests: requestCounts[namespace.id])
                            }
                        }
                    }
                }
            }
            .navigationTitle(.tabsDurableObjects)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(.durableObjectsSearch))
            .resourceStatus(
                namespaces,
                emptyTitle: .durableObjectsEmptyTitle,
                emptySystemImage: "shippingbox",
                emptyDescription: .durableObjectsEmptyMessage
            )
            .navigationDestination(for: DurableObjectNamespace.self) { namespace in
                NamespaceDetailView(client: client, accountId: accountId, namespace: namespace)
            }
            .task { await reload() }
            .refreshable { await reload() }
        }
    }

    private func reload() async {
        async let namespacesLoad: Void = namespaces.refresh {
            try await client.durableObjectNamespaces(accountId: accountId)
        }
        async let analyticsLoad: Void = analytics.refresh {
            try await client.durableObjectAnalytics(accountId: accountId, range: .day)
        }
        _ = await (namespacesLoad, analyticsLoad)
    }
}
