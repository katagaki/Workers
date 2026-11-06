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

    struct Needle: Encodable {
        let value: String
    }

    struct Parameters: Encodable {
        let filters: [Filter]
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
