import Foundation

public struct AIAnalyticsPoint: Codable, Hashable, Sendable {
    public let date: Date
    public let modelId: String
    public let requests: Int
    public let errors: Int
    public let neurons: Double
    public let inputTokens: Double
    public let outputTokens: Double
    public let inferenceTimeMilliseconds: Double
}
