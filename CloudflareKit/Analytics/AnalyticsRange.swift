import Foundation

public enum AnalyticsRange: String, Codable, CaseIterable, Identifiable, Sendable {
    case day
    case week
    case month

    public var id: String { rawValue }

    public var duration: TimeInterval {
        switch self {
        case .day: return 24 * 60 * 60
        case .week: return 7 * 24 * 60 * 60
        case .month: return 30 * 24 * 60 * 60
        }
    }

    public var usesHourlyBuckets: Bool {
        self != .month
    }

    public var bucketComponent: Calendar.Component {
        usesHourlyBuckets ? .hour : .day
    }

    public func interval(endingAt endDate: Date = .now) -> DateInterval {
        DateInterval(start: endDate.addingTimeInterval(-duration), end: endDate)
    }
}
