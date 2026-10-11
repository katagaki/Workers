import Foundation

public struct AIModelSchema: Codable, Sendable {
    public let input: JSONValue
    public let output: JSONValue

    public func supports(_ field: String) -> Bool {
        contains(field, in: input)
    }

    private func contains(_ field: String, in schema: JSONValue) -> Bool {
        if schema["properties"]?[field] != nil { return true }
        for key in ["oneOf", "anyOf", "allOf"] {
            if case .array(let alternatives) = schema[key], alternatives.contains(where: { contains(field, in: $0) }) {
                return true
            }
        }
        return false
    }
}
