import Foundation

extension LogQuery {
    struct SearchPattern: Hashable {
        let plain: String?
        let regex: String
        let isAlternation: Bool

        init(text: String) {
            plain = text
            regex = Self.escaped(text)
            isAlternation = false
        }

        init(allOf parts: [SearchPattern]) {
            let plainParts = parts.compactMap(\.plain)
            plain = plainParts.count == parts.count ? plainParts.joined(separator: " ") : nil
            regex = parts.map { $0.isAlternation ? "(?:\($0.regex))" : $0.regex }.joined(separator: " ")
            isAlternation = false
        }

        init(anyOf parts: [SearchPattern]) {
            plain = nil
            regex = parts.map(\.regex).joined(separator: "|")
            isAlternation = true
        }

        private static func escaped(_ text: String) -> String {
            text.reduce(into: "") { escaped, character in
                if "\\.+*?()|[]{}^$".contains(character) { escaped.append("\\") }
                escaped.append(character)
            }
        }
    }

    /// The API takes a single search for the whole query, so text has to be lifted out of the filter tree.
    /// Text-only branches become one regex, and text shared by every OR branch is factored out.
    static func extractSearch(from node: LogQueryNode) throws -> (SearchPattern?, LogQueryExpression?) {
        switch node {
        case .text(let text):
            return (SearchPattern(text: text), nil)
        case .filter(let filter):
            return (nil, .filter(filter))
        case .all(let parts):
            let extracted = try parts.map(extractSearch)
            let patterns = extracted.compactMap(\.0)
            let expressions = extracted.compactMap(\.1)
            let pattern = patterns.isEmpty ? nil : patterns.count == 1 ? patterns[0] : SearchPattern(allOf: patterns)
            let expression = expressions.isEmpty ? nil : expressions.count == 1 ? expressions[0] : LogQueryExpression.all(expressions)
            return (pattern, expression)
        case .any(let branches):
            let extracted = try branches.map(extractSearch)
            if extracted.allSatisfy({ $0.1 == nil }) {
                return (SearchPattern(anyOf: extracted.compactMap(\.0)), nil)
            }
            let expressions = extracted.compactMap(\.1)
            guard expressions.count == extracted.count, Set(extracted.map(\.0)).count == 1 else {
                throw LogQueryParseError.mixedSearch
            }
            return (extracted[0].0, .any(expressions))
        }
    }
}
