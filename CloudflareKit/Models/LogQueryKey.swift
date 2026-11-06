import Foundation

public enum LogQueryValueType: String, Codable, Hashable, Sendable {
    case string
    case number
    case boolean
}

public struct LogQueryKey: Codable, Hashable, Identifiable, Sendable {
    public let key: String
    public let type: LogQueryValueType

    public init(key: String, type: LogQueryValueType) {
        self.key = key
        self.type = type
    }

    public var id: String { "\(key)-\(type.rawValue)" }

    /// Offered before discovery finishes, and when the token cannot reach the keys endpoint.
    public static let common: [LogQueryKey] = [
        LogQueryKey(key: "$metadata.message", type: .string),
        LogQueryKey(key: "$metadata.level", type: .string),
        LogQueryKey(key: "$metadata.error", type: .string),
        LogQueryKey(key: "$metadata.statusCode", type: .number),
        LogQueryKey(key: "$metadata.url", type: .string),
        LogQueryKey(key: "$metadata.trigger", type: .string),
        LogQueryKey(key: "$metadata.origin", type: .string),
        LogQueryKey(key: "$workers.outcome", type: .string),
        LogQueryKey(key: "$workers.eventType", type: .string),
        LogQueryKey(key: "$workers.cpuTimeMs", type: .number),
        LogQueryKey(key: "$workers.wallTimeMs", type: .number),
        LogQueryKey(key: "$workers.requestId", type: .string)
    ]

    public static func merged(with discovered: [LogQueryKey]) -> [LogQueryKey] {
        let commonIdentifiers = Set(common.map(\.id))
        let additional = discovered
            .filter { !commonIdentifiers.contains($0.id) }
            .sorted { $0.key < $1.key }
        return common + additional
    }
}
