import Foundation

struct DurableObjectInvocationsAccount: Decodable {
    struct Group: Decodable {
        struct Sum: Decodable {
            let requests: Int
        }

        struct Dimensions: Decodable {
            let datetimeHour: Date?
            let date: Date?
            let namespaceId: String
        }

        let sum: Sum
        let dimensions: Dimensions
    }

    let durableObjectsInvocationsAdaptiveGroups: [Group]
}
