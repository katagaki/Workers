import CloudflareKit
import SwiftUI

struct R2BucketsListView: View {
    let client: CloudflareClient
    let accountId: String
    let buckets: CachedResource<[R2Bucket]>

    @State private var searchText = ""

    private var filteredBuckets: [R2Bucket] {
        let all = (buckets.value ?? []).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            RefreshErrorSection(resource: buckets)
            ForEach(filteredBuckets) { bucket in
                NavigationLink(value: StorageDestination.r2Bucket(bucketName: bucket.name, prefix: "")) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(bucket.name)
                            .lineLimit(1)
                        if let location = bucket.location {
                            Text(location)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(.storageR2Title)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(.storageR2Search))
        .resourceStatus(
            buckets,
            emptyTitle: .storageR2EmptyTitle,
            emptySystemImage: "archivebox",
            emptyDescription: .storageR2EmptyMessage
        )
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func reload() async {
        await buckets.refresh {
            try await client.r2Buckets(accountId: accountId)
        }
    }
}
