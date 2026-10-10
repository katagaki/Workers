import CloudflareKit
import SwiftUI

extension AnalyticsRange {
    var title: LocalizedStringResource {
        switch self {
        case .day: .sharedRangesDay
        case .week: .sharedRangesWeek
        case .month: .sharedRangesMonth
        }
    }
}
