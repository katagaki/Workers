import Foundation

struct RequestTotalAccount: Decodable {
    struct Group: Decodable {
        struct Sum: Decodable {
            let requests: Int
        }

        let sum: Sum
    }

    let workersInvocationsAdaptive: [Group]?
    let pagesFunctionsInvocationsAdaptiveGroups: [Group]?
}
