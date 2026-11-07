import Foundation

extension LogQueryAutocomplete {
    struct ContextBuilder {
        let characters: [Character]
        let cursor: Int

        var none: LogQueryCompletionContext {
            LogQueryCompletionContext(position: .none, partial: "", replacement: cursor..<cursor)
        }

        func key(partial: String, start: Int, allowsConnector: Bool) -> LogQueryCompletionContext {
            LogQueryCompletionContext(
                position: .key,
                partial: partial,
                replacement: start..<termEnd(partial: partial),
                allowsConnector: allowsConnector
            )
        }

        func operation(key: String, partial: String, start: Int) -> LogQueryCompletionContext {
            LogQueryCompletionContext(
                position: .operation(key: key),
                partial: partial,
                replacement: start..<termEnd(partial: partial)
            )
        }

        func afterOperator(_ clause: LogQueryClause, operation: LogQueryOperator, endsWithSpace: Bool) -> LogQueryCompletionContext {
            if let value = clause.value {
                if value.isQuoted && !value.isClosed {
                    return valueContext(clause, operation: operation, partial: value.text, start: value.range.lowerBound, isQuoted: true)
                }
                if endsWithSpace { return key(partial: "", start: cursor, allowsConnector: true) }
                guard !value.isQuoted else { return none }
                return valueContext(clause, operation: operation, partial: value.text, start: value.range.lowerBound, isQuoted: false)
            }
            let isWordOperator = !LogQueryOperator.symbolic.contains(operation)
            if isWordOperator, !endsWithSpace, let operatorToken = clause.operatorToken {
                return self.operation(key: clause.term.text, partial: operatorToken.text, start: operatorToken.range.lowerBound)
            }
            guard operation.takesValue else { return key(partial: "", start: cursor, allowsConnector: true) }
            return valueContext(clause, operation: operation, partial: "", start: cursor, isQuoted: false)
        }

        private func valueContext(
            _ clause: LogQueryClause,
            operation: LogQueryOperator,
            partial: String,
            start: Int,
            isQuoted: Bool
        ) -> LogQueryCompletionContext {
            LogQueryCompletionContext(
                position: .value(key: clause.term.text, operation: operation),
                partial: partial,
                replacement: start..<valueEnd(partial: partial, isQuoted: isQuoted)
            )
        }

        private func termEnd(partial: String) -> Int {
            guard !partial.isEmpty else { return cursor }
            var end = cursor
            while end < characters.count, !characters[end].isWhitespace, !"=<>!)".contains(characters[end]) {
                end += 1
            }
            return end
        }

        private func valueEnd(partial: String, isQuoted: Bool) -> Int {
            guard isQuoted || !partial.isEmpty else { return cursor }
            var end = cursor
            while end < characters.count {
                if isQuoted, LogQueryScanner.isQuote(characters[end]) { return end + 1 }
                if !isQuoted, characters[end].isWhitespace || characters[end] == ")" { return end }
                end += 1
            }
            return end
        }
    }
}
