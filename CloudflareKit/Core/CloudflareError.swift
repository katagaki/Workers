import Foundation

public enum CloudflareError: LocalizedError, Sendable {
    case missingToken
    case noAccessibleAccounts
    case accountAccessDenied
    case invalidResponse
    case http(statusCode: Int)
    case api(messages: [String])
    case graphQL(messages: [String])
    case r2ObjectTooLarge(key: String, limit: Int)
    case r2KeyExists(key: String)
    case r2CustomMetadataUnsupported(key: String)
    case r2CopyVerificationFailed(key: String)

    public var errorDescription: String? {
        switch self {
        case .missingToken:
            return String(localized: .errorsMissingToken)
        case .noAccessibleAccounts:
            return String(localized: .errorsNoAccessibleAccounts)
        case .accountAccessDenied:
            return String(localized: .errorsAccountAccessDenied)
        case .invalidResponse:
            return String(localized: .errorsInvalidResponse)
        case .http(let statusCode):
            switch statusCode {
            case 401:
                return String(localized: .errorsInvalidToken)
            case 403:
                return String(localized: .errorsPermissionDenied)
            default:
                return String(localized: .errorsHttpStatus(statusCode))
            }
        case .r2ObjectTooLarge(let key, let limit):
            let formattedLimit = limit.formatted(.byteCount(style: .binary))
            return String(localized: .errorsR2ObjectTooLarge(key, formattedLimit))
        case .r2KeyExists(let key):
            return String(localized: .errorsR2KeyExists(key))
        case .r2CustomMetadataUnsupported(let key):
            return String(localized: .errorsR2CustomMetadataUnsupported(key))
        case .r2CopyVerificationFailed(let key):
            return String(localized: .errorsR2CopyVerificationFailed(key))
        case .api(let messages), .graphQL(let messages):
            let description = messages.joined(separator: "\n")
            let normalizedDescription = description.lowercased()
            if ["invalid access token", "invalid api token", "invalid request headers", "authentication error", "unable to authenticate"].contains(where: normalizedDescription.contains) {
                return String(localized: .errorsInvalidToken)
            }
            if ["permission", "not authorized", "unauthorized", "forbidden", "not authorised", "unauthorised"].contains(where: normalizedDescription.contains) {
                return String(localized: .errorsPermissionDenied) + "\n\n" + description
            }
            return description
        }
    }
}
