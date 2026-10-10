import Foundation

enum TokenStorageError: LocalizedError {
    case saveFailed

    var errorDescription: String? {
        String(localized: .signInSaveFailedMessage)
    }
}
