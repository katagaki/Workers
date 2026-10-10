import Foundation

public struct WorkerAnnotations: Codable, Hashable, Sendable {
    public let message: String?
    public let tag: String?
    public let triggeredBy: String?

    enum CodingKeys: String, CodingKey {
        case message = "workers/message"
        case tag = "workers/tag"
        case triggeredBy = "workers/triggeredBy"
    }
}
