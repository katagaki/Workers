import Foundation

struct LogQueryToken: Hashable, Sendable {
    let range: Range<Int>
    let text: String
    var isQuoted = false
    var isClosed = true
}

struct LogQueryClause: Hashable, Sendable {
    let term: LogQueryToken
    var operatorToken: LogQueryToken?
    var operation: LogQueryOperator?
    var value: LogQueryToken?

    /// Only the uppercase spelling connects, so that searches like "this or that" stay plain text.
    var connector: LogQueryConnector? {
        guard operation == nil, !term.isQuoted else { return nil }
        return LogQueryConnector(rawValue: term.text)
    }
}

struct LogQueryScanner {
    private let characters: [Character]
    private let knownKeys: Set<String>
    private var position = 0

    static func clauses(in characters: [Character], knownKeys: Set<String>) -> [LogQueryClause] {
        var scanner = LogQueryScanner(characters: characters, knownKeys: knownKeys)
        return scanner.scan()
    }

    /// Smart punctuation rewrites straight quotes on iOS, so curly quotes have to delimit too.
    static func isQuote(_ character: Character) -> Bool {
        character == "\"" || character == "\u{201C}" || character == "\u{201D}"
    }

    private init(characters: [Character], knownKeys: Set<String>) {
        self.characters = characters
        self.knownKeys = knownKeys
    }

    private mutating func scan() -> [LogQueryClause] {
        var clauses: [LogQueryClause] = []
        while true {
            skipWhitespace()
            guard position < characters.count else { return clauses }
            if Self.isQuote(characters[position]) {
                clauses.append(LogQueryClause(term: readQuoted()))
            } else {
                clauses.append(readClause())
            }
        }
    }

    private mutating func readClause() -> LogQueryClause {
        let term = readTerm()
        let afterTerm = position
        skipWhitespace()
        guard let (operation, operatorToken) = readOperator(after: term) else {
            position = afterTerm
            return LogQueryClause(term: term)
        }
        var clause = LogQueryClause(term: term, operatorToken: operatorToken, operation: operation)
        guard operation.takesValue else { return clause }
        skipWhitespace()
        guard position < characters.count else { return clause }
        clause.value = Self.isQuote(characters[position]) ? readQuoted() : readUntilWhitespace()
        return clause
    }

    private mutating func readTerm() -> LogQueryToken {
        let start = position
        while position < characters.count,
              !characters[position].isWhitespace,
              symbolicOperator(at: position) == nil {
            position += 1
        }
        guard position == start else { return token(from: start) }
        return readUntilWhitespace()
    }

    private mutating func readOperator(after term: LogQueryToken) -> (LogQueryOperator, LogQueryToken)? {
        let start = position
        if let operation = symbolicOperator(at: start) {
            position += operation.rawValue.count
            return (operation, token(from: start))
        }
        guard isKeyLike(term.text), position < characters.count else { return nil }
        let word = readUntilWhitespace()
        guard let operation = LogQueryOperator(rawValue: word.text) else { return nil }
        return (operation, word)
    }

    /// Word operators need a key on the left so that plain searches like "errors in production" stay text.
    private func isKeyLike(_ term: String) -> Bool {
        knownKeys.contains(term) || term.hasPrefix("$") || term.contains(".")
    }

    private func symbolicOperator(at index: Int) -> LogQueryOperator? {
        LogQueryOperator.symbolic.first { operation in
            let symbol = Array(operation.rawValue)
            guard index + symbol.count <= characters.count else { return false }
            return Array(characters[index..<(index + symbol.count)]) == symbol
        }
    }

    private mutating func readUntilWhitespace() -> LogQueryToken {
        let start = position
        while position < characters.count, !characters[position].isWhitespace {
            position += 1
        }
        return token(from: start)
    }

    private mutating func readQuoted() -> LogQueryToken {
        let start = position
        position += 1
        var text = ""
        var isClosed = false
        while position < characters.count {
            let character = characters[position]
            if character == "\\", position + 1 < characters.count,
               characters[position + 1] == "\\" || Self.isQuote(characters[position + 1]) {
                text.append(characters[position + 1])
                position += 2
                continue
            }
            position += 1
            if Self.isQuote(character) {
                isClosed = true
                break
            }
            text.append(character)
        }
        return LogQueryToken(range: start..<position, text: text, isQuoted: true, isClosed: isClosed)
    }

    private mutating func skipWhitespace() {
        while position < characters.count, characters[position].isWhitespace {
            position += 1
        }
    }

    private func token(from start: Int) -> LogQueryToken {
        LogQueryToken(range: start..<position, text: String(characters[start..<position]))
    }
}
