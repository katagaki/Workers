import Foundation

public enum LogQueryOperator: String, CaseIterable, Hashable, Sendable {
    case equals = "="
    case notEquals = "!="
    case greater = ">"
    case greaterOrEqual = ">="
    case less = "<"
    case lessOrEqual = "<="
    case contains
    case excludes
    case startsWith = "starts"
    case endsWith = "ends"
    case matches
    case isIn = "in"
    case exists
    case missing

    static let symbolic: [LogQueryOperator] = [
        .greaterOrEqual, .lessOrEqual, .notEquals, .equals, .greater, .less
    ]

    public static func available(for type: LogQueryValueType?) -> [LogQueryOperator] {
        switch type {
        case .string:
            [.equals, .notEquals, .contains, .excludes, .startsWith, .endsWith, .matches, .isIn, .exists, .missing]
        case .number:
            [.equals, .notEquals, .greater, .greaterOrEqual, .less, .lessOrEqual, .isIn, .exists, .missing]
        case .boolean:
            [.equals, .notEquals, .exists, .missing]
        case nil:
            allCases
        }
    }

    var apiOperation: String {
        switch self {
        case .equals: "eq"
        case .notEquals: "neq"
        case .greater: "gt"
        case .greaterOrEqual: "gte"
        case .less: "lt"
        case .lessOrEqual: "lte"
        case .contains: "includes"
        case .excludes: "not_includes"
        case .startsWith: "starts_with"
        case .endsWith: "ends_with"
        case .matches: "regex"
        case .isIn: "in"
        case .exists: "exists"
        case .missing: "is_null"
        }
    }

    var takesValue: Bool {
        self != .exists && self != .missing
    }

    var isNumericComparison: Bool {
        switch self {
        case .greater, .greaterOrEqual, .less, .lessOrEqual: true
        default: false
        }
    }

    var isTextComparison: Bool {
        switch self {
        case .contains, .excludes, .startsWith, .endsWith, .matches: true
        default: false
        }
    }
}
