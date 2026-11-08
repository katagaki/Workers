import Foundation

public struct LogQueryValue: Codable, Hashable, Sendable {
    public let key: String
    public let type: LogQueryValueType
    public let value: JSONValue
}
