import Foundation

struct WorkerInvocationsAccount: Decodable {
    struct Group: Decodable {
        struct Sum: Decodable {
            let requests: Int
            let errors: Int
            let subrequests: Int
        }

        struct Quantiles: Decodable {
            let cpuTimeP50: Double
            let cpuTimeP99: Double
        }

        struct Dimensions: Decodable {
            let datetimeHour: Date?
            let date: Date?
            let scriptName: String
        }

        let sum: Sum
        let quantiles: Quantiles
        let dimensions: Dimensions
    }

    let workersInvocationsAdaptive: [Group]
}
