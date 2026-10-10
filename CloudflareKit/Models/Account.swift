import Foundation

public struct Account: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let type: String?
    public let createdOn: Date?
}
