import Foundation

public struct Zone: Codable, Hashable, Identifiable, Sendable {
    public struct Plan: Codable, Hashable, Sendable {
        public let id: String?
        public let name: String?
    }

    public struct Owner: Codable, Hashable, Sendable {
        public let id: String?
        public let name: String?
    }

    public let id: String
    public let name: String
    public let status: String
    public let paused: Bool?
    public let type: String?
    public let developmentMode: Int?
    public let nameServers: [String]?
    public let originalNameServers: [String]?
    public let originalRegistrar: String?
    public let plan: Plan?
    public let account: Owner?
    public let createdOn: Date?
    public let modifiedOn: Date?
    public let activatedOn: Date?
}
