import Foundation

indirect enum LogQueryNode: Hashable, Sendable {
    case filter(LogQuery.Filter)
    case text(String)
    case all([LogQueryNode])
    case any([LogQueryNode])
}

/// AND binds tighter than OR, and adjacent conditions without a connector are joined with AND.
struct LogQueryParser {
    private let clauses: [LogQueryClause]
    private let keys: [LogQueryKey]
    private var index = 0

    init(clauses: [LogQueryClause], keys: [LogQueryKey]) {
        self.clauses = clauses
        self.keys = keys
    }

    mutating func parse() throws -> LogQueryNode {
        let node = try parseAny()
        guard index == clauses.count else { throw LogQueryParseError.unbalancedParentheses }
        return node
    }

    private mutating func parseAny() throws -> LogQueryNode {
        var branches = [try parseAll()]
        while index < clauses.count, clauses[index].connector == .or {
            index += 1
            branches.append(try parseAll())
        }
        return branches.count == 1 ? branches[0] : .any(branches.flatMap(Self.anyBranches))
    }

    private mutating func parseAll() throws -> LogQueryNode {
        var parts: [LogQueryNode] = []
        while index < clauses.count {
            let clause = clauses[index]
            if clause.grouping == .close || clause.connector == .or { break }
            if clause.connector == .and {
                guard !parts.isEmpty else { throw LogQueryParseError.missingCondition }
                index += 1
                guard index < clauses.count, clauses[index].startsCondition else {
                    throw LogQueryParseError.missingCondition
                }
                continue
            }
            parts.append(try parseUnit())
        }
        guard !parts.isEmpty else { throw LogQueryParseError.missingCondition }
        return parts.count == 1 ? parts[0] : .all(parts.flatMap(Self.allParts))
    }

    private mutating func parseUnit() throws -> LogQueryNode {
        let clause = clauses[index]
        index += 1
        if clause.grouping == .open {
            let inner = try parseAny()
            guard index < clauses.count, clauses[index].grouping == .close else {
                throw LogQueryParseError.unbalancedParentheses
            }
            index += 1
            return inner
        }
        guard clause.term.isClosed, clause.value?.isClosed ?? true else {
            throw LogQueryParseError.unterminatedQuote
        }
        guard let operation = clause.operation else { return .text(clause.term.text) }
        return .filter(try LogQuery.filter(for: clause, operation: operation, keys: keys))
    }

    private static func anyBranches(_ node: LogQueryNode) -> [LogQueryNode] {
        if case .any(let branches) = node { return branches }
        return [node]
    }

    private static func allParts(_ node: LogQueryNode) -> [LogQueryNode] {
        if case .all(let parts) = node { return parts }
        return [node]
    }
}

private extension LogQueryClause {
    var startsCondition: Bool {
        connector == nil && grouping != .close
    }
}
