import Foundation

public struct WorkerSchedule: Codable, Hashable, Identifiable, Sendable {
    public let cron: String
    public let createdOn: Date?
    public let modifiedOn: Date?

    public var id: String { cron }
}
