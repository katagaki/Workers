import CloudflareKit
import SwiftUI

extension LogQueryValueType {
    var title: LocalizedStringResource {
        switch self {
        case .string: .logsQueryTypeString
        case .number: .logsQueryTypeNumber
        case .boolean: .logsQueryTypeBoolean
        }
    }
}

extension LogQueryOperator {
    var title: LocalizedStringResource {
        switch self {
        case .equals: .logsQueryOperatorEquals
        case .notEquals: .logsQueryOperatorNotEquals
        case .greater: .logsQueryOperatorGreater
        case .greaterOrEqual: .logsQueryOperatorGreaterOrEqual
        case .less: .logsQueryOperatorLess
        case .lessOrEqual: .logsQueryOperatorLessOrEqual
        case .contains: .logsQueryOperatorContains
        case .excludes: .logsQueryOperatorExcludes
        case .startsWith: .logsQueryOperatorStartsWith
        case .endsWith: .logsQueryOperatorEndsWith
        case .matches: .logsQueryOperatorMatches
        case .isIn: .logsQueryOperatorIn
        case .exists: .logsQueryOperatorExists
        case .missing: .logsQueryOperatorMissing
        }
    }
}

extension LogQueryConnector {
    var title: LocalizedStringResource {
        switch self {
        case .or: .logsQueryConnectorOr
        case .and: .logsQueryConnectorAnd
        }
    }
}

extension LogQueryParseError {
    var message: LocalizedStringResource {
        switch self {
        case .missingValue: .logsQueryErrorMissingValue
        case .missingCondition: .logsQueryErrorMissingCondition
        case .invalidValue: .logsQueryErrorInvalidValue
        case .unterminatedQuote: .logsQueryErrorUnterminatedQuote
        case .mixedSearch: .logsQueryErrorMixedSearch
        }
    }
}
