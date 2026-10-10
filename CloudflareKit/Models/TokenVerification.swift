import Foundation

public struct TokenVerification: Codable, Hashable, Sendable {
    public let id: String
    public let status: String
    public let expiresOn: Date?
}
