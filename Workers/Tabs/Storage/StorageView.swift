import CloudflareKit
import SwiftUI

struct StorageView: View {
    let resources: AccountResources

    var body: some View {
        NavigationStack {
            List {
                ForEach(StorageCategory.allCases, id: \.self) { category in
                    NavigationLink(value: category) {
                        LabeledContent {
                            if let count = resources.count(of: category) {
                                Text(count, format: .number)
                            }
                        } label: {
                            SettingsLabel(title: category.title, systemImage: category.systemImage, color: category.color)
                        }
                    }
                }
            }
            .navigationTitle(.tabsStorage)
            .accountToolbar()
            .navigationDestination(for: StorageCategory.self) { category in
                category.view(resources: resources)
            }
            .navigationDestination(for: StorageDestination.self) { destination in
                destination.view(client: resources.client, accountId: resources.accountId)
            }
            .task { await resources.reloadStorage() }
            .refreshable { await resources.reloadStorage() }
        }
    }
}
