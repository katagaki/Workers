import Foundation

struct GraphQLResponse<DataType: Decodable>: Decodable {
    struct GraphQLErrorMessage: Decodable {
        let message: String
    }

    let data: DataType?
    let errors: [GraphQLErrorMessage]?
}
