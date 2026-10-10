import Foundation

struct ResultInfo: Decodable {
    let page: Int?
    let perPage: Int?
    let count: Int?
    let totalCount: Int?
    let totalPages: Int?
    let cursor: String?
}
