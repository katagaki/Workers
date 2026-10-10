import Foundation

public struct KVKey: Codable, Hashable, Identifiable, Sendable {
    public let name: String
    public let expiration: Date?
    public let metadata: JSONValue?

    public var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name
        case expiration
        case metadata
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        metadata = try container.decodeIfPresent(JSONValue.self, forKey: .metadata)
        // KV returns expiration as Unix seconds, which the shared date strategy would read as milliseconds.
        if let seconds = try? container.decodeIfPresent(Double.self, forKey: .expiration) {
            expiration = Date(timeIntervalSince1970: seconds)
        } else {
            expiration = try? container.decodeIfPresent(Date.self, forKey: .expiration)
        }
    }
}
