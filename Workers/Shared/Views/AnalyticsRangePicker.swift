import CloudflareKit
import SwiftUI

struct AnalyticsRangePicker: View {
    @Binding var range: AnalyticsRange

    var body: some View {
        Picker(.sharedTimeRange, selection: $range) {
            ForEach(AnalyticsRange.allCases) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }
}
