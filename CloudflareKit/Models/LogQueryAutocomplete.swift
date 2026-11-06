import Foundation

public enum LogQueryAutocomplete {
    public static func context(in text: String, cursor: Int, keys: [LogQueryKey]) -> LogQueryCompletionContext {
        let characters = Array(text)
        let cursor = min(max(cursor, 0), characters.count)
        let knownKeys = Set(keys.map(\.key))
        let clauses = LogQueryScanner.clauses(in: Array(characters[..<cursor]), knownKeys: knownKeys)
        let endsWithSpace = cursor > 0 && characters[cursor - 1].isWhitespace
        let builder = ContextBuilder(characters: characters, cursor: cursor)

        guard let last = clauses.last else { return builder.key(partial: "", start: cursor) }
        if let operation = last.operation {
            return builder.afterOperator(last, operation: operation, endsWithSpace: endsWithSpace)
        }
        if last.term.isQuoted {
            return last.term.isClosed && endsWithSpace ? builder.key(partial: "", start: cursor) : builder.none
        }
        if endsWithSpace {
            guard knownKeys.contains(last.term.text) else { return builder.key(partial: "", start: cursor) }
            return builder.operation(key: last.term.text, partial: "", start: cursor)
        }
        if clauses.count >= 2, isPartialOperator(last.term.text, after: clauses[clauses.count - 2], keys: keys) {
            return builder.operation(key: clauses[clauses.count - 2].term.text, partial: last.term.text, start: last.term.range.lowerBound)
        }
        return builder.key(partial: last.term.text, start: last.term.range.lowerBound)
    }

    public static func suggestions(
        for context: LogQueryCompletionContext,
        keys: [LogQueryKey],
        values: [LogQueryValue] = [],
        limit: Int = 12
    ) -> [LogQuerySuggestion] {
        switch context.position {
        case .none:
            []
        case .key:
            Array(keySuggestions(for: context, keys: keys).prefix(limit))
        case .operation(let key):
            operators(for: key, partial: context.partial, keys: keys).map { operation in
                LogQuerySuggestion(
                    kind: .operation(operation),
                    text: operation.rawValue,
                    insertion: operation.rawValue,
                    replacement: context.replacement
                )
            }
        case .value:
            Array(valueSuggestions(for: context, values: values).prefix(limit))
        }
    }

    public static func applying(_ suggestion: LogQuerySuggestion, to text: String) -> (text: String, cursor: Int) {
        var characters = Array(text)
        let upperBound = min(suggestion.replacement.upperBound, characters.count)
        let lowerBound = min(suggestion.replacement.lowerBound, upperBound)
        let hasFollowingSpace = upperBound < characters.count && characters[upperBound].isWhitespace
        let insertion = Array(suggestion.insertion + (hasFollowingSpace ? "" : " "))
        characters.replaceSubrange(lowerBound..<upperBound, with: insertion)
        return (String(characters), lowerBound + insertion.count + (hasFollowingSpace ? 1 : 0))
    }

    private static func isPartialOperator(_ partial: String, after clause: LogQueryClause, keys: [LogQueryKey]) -> Bool {
        guard clause.operation == nil, !clause.term.isQuoted, keys.contains(where: { $0.key == clause.term.text }) else {
            return false
        }
        return !operators(for: clause.term.text, partial: partial, keys: keys).isEmpty
    }

    private static func operators(for key: String, partial: String, keys: [LogQueryKey]) -> [LogQueryOperator] {
        let type = keys.first { $0.key == key }?.type
        let partial = partial.lowercased()
        return LogQueryOperator.available(for: type).filter { partial.isEmpty || $0.rawValue.hasPrefix(partial) }
    }

    private static func keySuggestions(for context: LogQueryCompletionContext, keys: [LogQueryKey]) -> [LogQuerySuggestion] {
        var seenKeys = Set<String>()
        let matches = keys.compactMap { key -> (key: LogQueryKey, rank: Int)? in
            guard seenKeys.insert(key.key).inserted, let rank = rank(of: key.key, partial: context.partial) else { return nil }
            return (key, rank)
        }
        let ordered = context.partial.isEmpty ? matches : matches.sorted {
            ($0.rank, $0.key.key.count, $0.key.key) < ($1.rank, $1.key.key.count, $1.key.key)
        }
        return ordered.map { match in
            LogQuerySuggestion(
                kind: .key(match.key.type),
                text: match.key.key,
                insertion: match.key.key,
                replacement: context.replacement
            )
        }
    }

    /// Lets people skip the "$metadata." prefix, which is slow to type on a phone keyboard.
    private static func rank(of key: String, partial: String) -> Int? {
        guard !partial.isEmpty else { return 0 }
        let key = key.lowercased()
        let partial = partial.lowercased()
        if key.hasPrefix(partial) { return 0 }
        let needle = partial.hasPrefix("$") ? String(partial.dropFirst()) : partial
        if key.split(separator: ".").last?.hasPrefix(needle) == true { return 1 }
        return key.contains(needle) ? 2 : nil
    }

    private static func valueSuggestions(for context: LogQueryCompletionContext, values: [LogQueryValue]) -> [LogQuerySuggestion] {
        var seenValues = Set<String>()
        let partial = context.partial.lowercased()
        return values.compactMap { value in
            let text = value.value.displayText
            let lowercased = text.lowercased()
            guard seenValues.insert(text).inserted,
                  lowercased != partial,
                  partial.isEmpty || lowercased.contains(partial) else { return nil }
            return LogQuerySuggestion(kind: .value, text: text, insertion: quoted(text), replacement: context.replacement)
        }
    }

    private static func quoted(_ value: String) -> String {
        let needsQuotes = value.isEmpty || value.contains { $0.isWhitespace || LogQueryScanner.isQuote($0) }
        guard needsQuotes else { return value }
        let escaped = value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}
