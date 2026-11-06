import Foundation

public struct LogQuerySuggestion: Hashable, Identifiable, Sendable {
    public enum Kind: Hashable, Sendable {
        case key(LogQueryValueType)
        case operation(LogQueryOperator)
        case value
    }

    public let kind: Kind
    public let text: String
    let insertion: String
    let replacement: Range<Int>

    public var id: String { "\(kind)-\(text)" }
}

public struct LogQueryCompletionContext: Hashable, Sendable {
    public enum Position: Hashable, Sendable {
        case none
        case key
        case operation(key: String)
        case value(key: String, operation: LogQueryOperator)
    }

    public let position: Position
    public let partial: String
    let replacement: Range<Int>
}
