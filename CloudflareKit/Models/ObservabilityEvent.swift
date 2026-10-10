import Foundation

public struct ObservabilityEvent: Codable, Hashable, Identifiable, Sendable {
    public struct Metadata: Codable, Hashable, Sendable {
        public let id: String
        public let level: String?
        public let message: String?
        public let error: String?
        public let service: String?
        public let trigger: String?
        public let statusCode: Double?
        public let duration: Double?
        public let url: String?
        public let type: String?
    }

    public struct WorkersInfo: Codable, Hashable, Sendable {
        public let eventType: String?
        public let scriptName: String?
        public let outcome: String?
        public let cpuTimeMs: Double?
        public let wallTimeMs: Double?
        public let requestId: String?
        public let event: JSONValue?
    }

    public let metadata: Metadata
    public let timestamp: Double
    public let dataset: String?
    public let source: JSONValue?
    public let workers: WorkersInfo?

    enum CodingKeys: String, CodingKey {
        case metadata = "$metadata"
        case timestamp
        case dataset
        case source
        case workers = "$workers"
    }

    public var id: String { metadata.id }

    public var date: Date {
        Date(timeIntervalSince1970: timestamp / 1000)
    }

    public var summary: String {
        if let message = metadata.message, !message.isEmpty { return message }
        if let error = metadata.error, !error.isEmpty { return error }
        if let message = source?["message"]?.displayText { return message }
        if let source { return source.displayText }
        return metadata.trigger ?? ""
    }

    public var isError: Bool {
        let level = metadata.level?.lowercased()
        return level == "error" || metadata.error != nil || workers?.outcome == "exception"
    }
}
