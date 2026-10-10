import Foundation

struct APIEnvelope<Result: Decodable>: Decodable {
    let success: Bool?
    let errors: [APIMessage]?
    let result: Result?
    let resultInfo: ResultInfo?
}
