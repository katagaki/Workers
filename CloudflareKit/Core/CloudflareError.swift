import Foundation

public enum CloudflareError: LocalizedError, Sendable {
    case missingToken
    case invalidResponse
    case http(statusCode: Int)
    case api(messages: [String])
    case graphQL(messages: [String])

    public var errorDescription: String? {
        switch self {
        case .missingToken:
            return String(localized: .errorsMissingToken)
        case .invalidResponse:
            return String(localized: .errorsInvalidResponse)
        case .http(let statusCode):
            return String(localized: .errorsHttpStatus(statusCode))
        case .api(let messages), .graphQL(let messages):
            return messages.joined(separator: "\n")
        }
    }
}
