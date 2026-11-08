import Foundation

struct TelemetryQuery: Encodable {
    struct Timeframe: Encodable {
        let from: Int
        let to: Int

        init(from startDate: Date, to endDate: Date) {
            from = Int(startDate.timeIntervalSince1970 * 1000)
            to = Int(endDate.timeIntervalSince1970 * 1000)
        }
    }

    struct Filter: Encodable {
        let key: String
        let operation: String
        let type: String
        let value: JSONValue?

        static func service(_ scriptName: String) -> Filter {
            Filter(key: "$metadata.service", operation: "eq", type: "string", value: .string(scriptName))
        }

        init(key: String, operation: String, type: String, value: JSONValue?) {
            self.key = key
            self.operation = operation
            self.type = type
            self.value = value
        }

        init(_ filter: LogQuery.Filter) {
            self.init(
                key: filter.key,
                operation: filter.operation.apiOperation,
                type: filter.type.rawValue,
                value: filter.value
            )
        }
    }

    struct FilterGroup: Encodable {
        let kind = "group"
        let filterCombination: String
        let filters: [FilterItem]
    }

    enum FilterItem: Encodable {
        case filter(Filter)
        case group(FilterGroup)

        static func items(for query: LogQuery) -> [FilterItem] {
            switch query.expression {
            case nil: []
            case .all(let parts): parts.map { item(for: $0) }
            case let expression?: [item(for: expression)]
            }
        }

        private static func item(for expression: LogQueryExpression) -> FilterItem {
            switch expression {
            case .filter(let filter): .filter(Filter(filter))
            case .all(let parts): .group(FilterGroup(filterCombination: "and", filters: parts.map { item(for: $0) }))
            case .any(let branches): .group(FilterGroup(filterCombination: "or", filters: branches.map { item(for: $0) }))
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .filter(let filter): try container.encode(filter)
            case .group(let group): try container.encode(group)
            }
        }
    }

    struct Needle: Encodable {
        let value: String
        let isRegex: Bool?
    }

    struct Parameters: Encodable {
        let filters: [FilterItem]
        var needle: Needle?
    }

    let queryId: String
    let timeframe: Timeframe
    let view: String
    let limit: Int
    let parameters: Parameters
}

struct TelemetryKeysQuery: Encodable {
    let filters: [TelemetryQuery.Filter]
    let from: Int
    let to: Int
    let limit: Int
}

struct TelemetryValuesQuery: Encodable {
    let datasets: [String]
    let key: String
    let type: String
    let timeframe: TelemetryQuery.Timeframe
    let filters: [TelemetryQuery.Filter]
    let limit: Int
}
