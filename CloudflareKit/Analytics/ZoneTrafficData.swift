import Foundation

struct ZoneTrafficData: Decodable {
    struct Group: Decodable {
        struct Sum: Decodable {
            let requests: Int
            let cachedRequests: Int
            let bytes: Int
            let cachedBytes: Int
            let threats: Int
            let pageViews: Int
        }

        struct Unique: Decodable {
            let uniques: Int
        }

        struct Dimensions: Decodable {
            let datetime: Date?
            let date: Date?
        }

        let sum: Sum
        let uniq: Unique
        let dimensions: Dimensions
    }

    let zoneTag: String
    let httpRequests1hGroups: [Group]?
    let httpRequests1dGroups: [Group]?
}
