import Foundation

public struct TailEvent: Codable, Hashable, Identifiable, Sendable {
    public struct Log: Codable, Hashable, Sendable {
        public let message: [JSONValue]?
        public let level: String?
        public let timestamp: Double?

        public var text: String {
            (message ?? []).map(\.displayText).joined(separator: " ")
        }
    }

    public struct TailException: Codable, Hashable, Sendable {
        public let name: String?
        public let message: String?
        public let timestamp: Double?
    }

    public var id = UUID()
    public let outcome: String?
    public let scriptName: String?
    public let exceptions: [TailException]?
    public let logs: [Log]?
    public let eventTimestamp: Double?
    public let event: JSONValue?

    enum CodingKeys: String, CodingKey {
        case outcome, scriptName, exceptions, logs, eventTimestamp, event
    }

    public var date: Date {
        Date(timeIntervalSince1970: (eventTimestamp ?? 0) / 1000)
    }

    public var requestMethod: String? {
        event?["request"]?["method"]?.stringValue
    }

    public var requestURL: String? {
        event?["request"]?["url"]?.stringValue
    }

    public var responseStatus: Int? {
        event?["response"]?["status"]?.numberValue.map { Int($0) }
    }

    public var cron: String? {
        event?["cron"]?.stringValue
    }

    public var isError: Bool {
        !(exceptions ?? []).isEmpty || (outcome != nil && outcome != "ok")
    }
}
