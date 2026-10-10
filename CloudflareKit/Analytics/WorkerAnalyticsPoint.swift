import Foundation

public struct WorkerAnalyticsPoint: Codable, Hashable, Identifiable, Sendable {
    public let date: Date
    public let scriptName: String
    public let requests: Int
    public let errors: Int
    public let subrequests: Int
    public let cpuTimeP50: Double
    public let cpuTimeP99: Double

    public var id: String { "\(scriptName)-\(date.timeIntervalSince1970)" }
}
