import Foundation

public enum LogQueryParseError: Error, Hashable, Sendable {
    case missingValue
    case missingCondition
    case invalidValue
    case unterminatedQuote
    case mixedSearch
}

public struct LogQuery: Hashable, Sendable {
    public struct Filter: Hashable, Sendable {
        public let key: String
        public let operation: LogQueryOperator
        public let type: LogQueryValueType
        public let value: JSONValue?
    }

    private struct Alternative {
        var filters: [Filter] = []
        var searchTerms: [String] = []

        var searchText: String? {
            searchTerms.isEmpty ? nil : searchTerms.joined(separator: " ")
        }
    }

    /// Filters within an alternative must all match, and any one alternative may match.
    public let alternatives: [[Filter]]
    public let searchText: String?
    public let isSearchRegex: Bool

    public init() {
        alternatives = []
        searchText = nil
        isSearchRegex = false
    }

    public init(parsing text: String, keys: [LogQueryKey] = LogQueryKey.common) throws {
        let clauses = LogQueryScanner.clauses(in: Array(text), knownKeys: Set(keys.map(\.key)))
        var alternatives = [Alternative()]
        var canConnect = false
        var needsCondition = false
        for clause in clauses {
            guard clause.term.isClosed, clause.value?.isClosed ?? true else {
                throw LogQueryParseError.unterminatedQuote
            }
            if let connector = clause.connector {
                guard canConnect else { throw LogQueryParseError.missingCondition }
                canConnect = false
                needsCondition = true
                if connector == .or { alternatives.append(Alternative()) }
                continue
            }
            canConnect = true
            needsCondition = false
            if let operation = clause.operation {
                alternatives[alternatives.count - 1].filters.append(try Self.filter(for: clause, operation: operation, keys: keys))
            } else {
                alternatives[alternatives.count - 1].searchTerms.append(clause.term.text)
            }
        }
        guard !needsCondition else { throw LogQueryParseError.missingCondition }

        if alternatives.count > 1, alternatives.allSatisfy({ $0.filters.isEmpty }) {
            self.alternatives = []
            searchText = alternatives.compactMap(\.searchText).map(Self.regexEscaped).joined(separator: "|")
            isSearchRegex = true
            return
        }
        // The API has a single search term per query, which cannot sit inside an OR group.
        let hasSharedSearch = Set(alternatives.map(\.searchText)).count == 1
        guard alternatives.count == 1 || (hasSharedSearch && alternatives.allSatisfy { !$0.filters.isEmpty }) else {
            throw LogQueryParseError.mixedSearch
        }
        self.alternatives = alternatives.map(\.filters).filter { !$0.isEmpty }
        searchText = alternatives[0].searchText
        isSearchRegex = false
    }

    private static func regexEscaped(_ text: String) -> String {
        text.reduce(into: "") { escaped, character in
            if "\\.+*?()|[]{}^$".contains(character) { escaped.append("\\") }
            escaped.append(character)
        }
    }

    private static func filter(for clause: LogQueryClause, operation: LogQueryOperator, keys: [LogQueryKey]) throws -> Filter {
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
