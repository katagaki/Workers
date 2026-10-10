import Foundation

struct ZoneOutcomesData: Decodable {
    struct Group: Decodable {
        struct Dimensions: Decodable {
            let datetimeHour: Date?
            let date: Date?
            let securityAction: String?
            let originResponseStatus: Int?
        }

        let count: Int
        let dimensions: Dimensions
    }

    let httpRequestsAdaptiveGroups: [Group]?
}
