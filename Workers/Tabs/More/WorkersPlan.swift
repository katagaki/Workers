import Foundation

enum WorkersPlan: String, CaseIterable, Identifiable {
    case free
    case paid

    var id: String { rawValue }

    var includedRequests: Int {
        switch self {
        case .free: 100_000
        case .paid: 10_000_000
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .free: .morePlanFree
        case .paid: .morePlanPaid
        }
    }

    func periodStart(for date: Date = .now) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        switch self {
        case .free:
            return calendar.startOfDay(for: date)
        case .paid:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? calendar.startOfDay(for: date)
        }
    }
}
