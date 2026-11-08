import Foundation

public enum LogQueryParseError: Error, Hashable, Sendable {
    case missingValue
    case missingCondition
    case invalidValue
    case unterminatedQuote
    case unbalancedParentheses
    case mixedSearch
}

public indirect enum LogQueryExpression: Hashable, Sendable {
    case filter(LogQuery.Filter)
    case all([LogQueryExpression])
    case any([LogQueryExpression])
}

public struct LogQuery: Hashable, Sendable {
    public struct Filter: Hashable, Sendable {
        public let key: String
        public let operation: LogQueryOperator
        public let type: LogQueryValueType
        public let value: JSONValue?
    }

    public let expression: LogQueryExpression?
    public let searchText: String?
    public let isSearchRegex: Bool

    public init() {
        expression = nil
        searchText = nil
        isSearchRegex = false
    }

    public init(parsing text: String, keys: [LogQueryKey] = LogQueryKey.common) throws {
        let clauses = LogQueryScanner.clauses(in: Array(text), knownKeys: Set(keys.map(\.key)))
        var parser = LogQueryParser(clauses: clauses, keys: keys)
        let (search, expression) = clauses.isEmpty ? (nil, nil) : try Self.extractSearch(from: try parser.parse())
        self.expression = expression
        searchText = search.map { $0.plain ?? $0.regex }
        isSearchRegex = search.map { $0.plain == nil } ?? false
    }
}

extension LogQuery {
    static func filter(for clause: LogQueryClause, operation: LogQueryOperator, keys: [LogQueryKey]) throws -> Filter {
        let key = clause.term.text
        let knownTypes = keys.filter { $0.key == key }.map(\.type)
        guard operation.takesValue else {
            return Filter(key: key, operation: operation, type: knownTypes.first ?? .string, value: nil)
        }
        guard let value = clause.value?.text, !value.isEmpty else {
            throw LogQueryParseError.missingValue
        }
        let type = resolvedType(of: value, operation: operation, knownTypes: knownTypes)
        return Filter(key: key, operation: operation, type: type, value: try typedValue(value, type: type, operation: operation))
    }

    private static func resolvedType(of value: String, operation: LogQueryOperator, knownTypes: [LogQueryValueType]) -> LogQueryValueType {
        if operation.isTextComparison { return .string }
        if operation.isNumericComparison { return .number }
        let literalType = literalType(of: value)
        if operation == .isIn { return knownTypes.first ?? .string }
        if knownTypes.contains(literalType) { return literalType }
        return knownTypes.first ?? literalType
    }

    private static func literalType(of value: String) -> LogQueryValueType {
        if Double(value) != nil { return .number }
        if value == "true" || value == "false" { return .boolean }
        return .string
    }

    private static func typedValue(_ value: String, type: LogQueryValueType, operation: LogQueryOperator) throws -> JSONValue {
        if operation == .isIn { return .string(value) }
        switch type {
        case .string:
            return .string(value)
        case .number:
            guard let number = Double(value) else { throw LogQueryParseError.invalidValue }
            return .number(number)
        case .boolean:
            guard value == "true" || value == "false" else { throw LogQueryParseError.invalidValue }
            return .bool(value == "true")
        }
    }
}
