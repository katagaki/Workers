import Foundation

struct APIMessage: Decodable {
    let code: Int?
    let message: String
}
