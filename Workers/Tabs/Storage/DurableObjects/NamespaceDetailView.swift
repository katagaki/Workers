import CloudflareKit
import SwiftUI

struct NamespaceDetailView: View {
    let client: CloudflareClient
    let accountId: String
    let namespace: DurableObjectNamespace

    @State private var range: AnalyticsRange = .day
    @State private var firstPage: CachedResource<DurableObjectPage>
    @State private var additionalObjects: [DurableObjectInstance] = []
    @State private var nextCursor: String?
    @State private var isLoadingMore = false
    @State private var loadMoreError: String?

    init(client: CloudflareClient, accountId: String, namespace: DurableObjectNamespace) {
        self.client = client
        self.accountId = accountId
        self.namespace = namespace
        _firstPage = State(initialValue: CachedResource(key: "do-objects-\(accountId)-\(namespace.id)"))
    }

    private var objects: [DurableObjectInstance] {
        (firstPage.value?.objects ?? []) + additionalObjects
    }

    var body: some View {
        List {
            Section {
                AnalyticsRangePicker(range: $range)
                    .listRowSeparator(.hidden)
                NamespaceAnalyticsSummary(client: client, accountId: accountId, namespaceId: namespace.id, range: range)
                    .id(range)
            } header: {
                Text(.tabsAnalytics)
            }

            Section(.sharedOverview) {
                if let className = namespace.className {
                    LabeledContent(.durableObjectsClass, value: className)
                }
                if let script = namespace.script {
                    LabeledContent(.durableObjectsWorker, value: script)
                }
                LabeledContent(.durableObjectsStorage, value: namespace.storageBackendTitle)
                LabeledContent(.durableObjectsNamespaceID) {
                    Text(namespace.id)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
            }

            Section {
                if firstPage.value == nil && firstPage.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let error = firstPage.error, firstPage.value == nil {
                    Text(error.localizedDescription)
                        .foregroundStyle(.secondary)
                } else if objects.isEmpty {
                    Text(.durableObjectsObjectsEmpty)
                        .foregroundStyle(.secondary)
                }
                ForEach(objects) { object in
                    DurableObjectRow(object: object)
                }
                if nextCursor != nil {
                    Button {
                        Task { await loadMore() }
                    } label: {
                        HStack {
                            Text(.durableObjectsObjectsLoadMore)
                            Spacer()
                            if isLoadingMore {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isLoadingMore)
                }
            } header: {
                Text(.durableObjectsObjectsHeader)
            } footer: {
                if let loadMoreError {
                    Text(loadMoreError)
                } else {
                    Text(.durableObjectsObjectsFooter)
                }
            }
        }
        .navigationTitle(namespace.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func reload() async {
        await firstPage.refresh {
            try await client.durableObjects(accountId: accountId, namespaceId: namespace.id)
        }
        additionalObjects = []
        nextCursor = firstPage.value?.nextCursor
    }

    private func loadMore() async {
        guard let cursor = nextCursor else { return }
        isLoadingMore = true
        loadMoreError = nil
        defer { isLoadingMore = false }
        do {
            let page = try await client.durableObjects(accountId: accountId, namespaceId: namespace.id, cursor: cursor)
            additionalObjects += page.objects
            nextCursor = page.nextCursor
        } catch {
            loadMoreError = error.localizedDescription
        }
    }
}
