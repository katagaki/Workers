import Foundation

public struct WorkerSettings: Codable, Hashable, Sendable {
    public struct Observability: Codable, Hashable, Sendable {
        public let enabled: Bool
        public let headSamplingRate: Double?
    }

    public struct Placement: Codable, Hashable, Sendable {
        public let mode: String?
    }

    public let bindings: [WorkerBinding]?
    public let compatibilityDate: String?
    public let compatibilityFlags: [String]?
    public let usageModel: String?
    public let logpush: Bool?
    public let observability: Observability?
    public let placement: Placement?
}
