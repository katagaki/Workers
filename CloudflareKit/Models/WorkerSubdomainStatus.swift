import Foundation

public struct WorkerSubdomainStatus: Codable, Hashable, Sendable {
    public let enabled: Bool
    public let previewsEnabled: Bool?
}
