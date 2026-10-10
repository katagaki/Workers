import CloudflareKit
import SwiftUI

struct ZoneAnalyticsSummary: View {
    let client: CloudflareClient
    let zoneId: String
    let range: AnalyticsRange

    @State private var analytics: CachedResource<[ZoneAnalyticsPoint]>

    init(client: CloudflareClient, zoneId: String, range: AnalyticsRange) {
        self.client = client
        self.zoneId = zoneId
        self.range = range
        _analytics = State(initialValue: CachedResource(key: "zone-analytics-\(zoneId)-\(range.rawValue)"))
    }

    var body: some View {
        Group {
            if analytics.value == nil, let error = analytics.error {
                Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let points = analytics.value {
                ZoneTrafficContent(points: points, range: range)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 160)
            }
        }
        .task {
            await analytics.refresh {
                try await client.zoneAnalytics(zoneIds: [zoneId], range: range)
            }
        }
    }
}
