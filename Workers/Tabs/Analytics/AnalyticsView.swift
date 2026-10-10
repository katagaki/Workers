import CloudflareKit
import SwiftUI

struct AnalyticsView: View {
    let client: CloudflareClient
    let accountId: String

    @AppStorage("AnalyticsRange") private var range: AnalyticsRange = .day
    @State private var refreshToken = UUID()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AnalyticsRangePicker(range: $range)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                Group {
                    WorkersAnalyticsSection(client: client, accountId: accountId, range: range)
                    DomainsAnalyticsSection(client: client, accountId: accountId, range: range)
                    DurableObjectsAnalyticsSection(client: client, accountId: accountId, range: range)
                }
                .id("\(range.rawValue)-\(refreshToken)")
            }
            .navigationTitle(.tabsAnalytics)
            .refreshable {
                refreshToken = UUID()
            }
        }
    }
}
