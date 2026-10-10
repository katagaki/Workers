import SwiftUI

enum LogWindow: String, CaseIterable, Identifiable {
    case hour
    case day
    case week

    var id: String { rawValue }

    var duration: TimeInterval {
        switch self {
        case .hour: 60 * 60
        case .day: 24 * 60 * 60
        case .week: 7 * 24 * 60 * 60
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .hour: .logsWindowsHour
        case .day: .logsWindowsDay
        case .week: .logsWindowsWeek
        }
    }
}
