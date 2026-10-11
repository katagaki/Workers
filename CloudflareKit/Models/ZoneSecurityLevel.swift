import Foundation

public struct ZoneSecurityLevel: Decodable, Sendable {
    public let value: String
    public let editable: Bool?

    public var isUnderAttack: Bool { value == "under_attack" }
}
