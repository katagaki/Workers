import Foundation

struct TelemetryQuery: Encodable {
    struct Timeframe: Encodable {
        let from: Int
        let to: Int
    }

    struct Filter: Encodable {
        let key: String
        let operation: String
        let type: String
        let value: String
    }

    struct Parameters: Encodable {
        let filters: [Filter]
    }

    let queryId: String
    let timeframe: Timeframe
    let view: String
    let limit: Int
    let parameters: Parameters
}
