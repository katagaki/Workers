import Foundation

nonisolated enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case notSignedIn
    case noAccount
    case workerNotFound
    case zoneNotFound
    case noPreviousDeployment
    case deploymentChanged

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notSignedIn: .intentsErrorNotSignedIn
        case .noAccount: .accountNoAccountMessage
        case .workerNotFound: .intentsErrorWorkerNotFound
        case .zoneNotFound: .intentsErrorZoneNotFound
        case .noPreviousDeployment: .intentsErrorNoPreviousDeployment
        case .deploymentChanged: .intentsErrorDeploymentChanged
        }
    }
}
