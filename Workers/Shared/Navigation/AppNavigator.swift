import CloudflareKit
import Observation

@Observable
final class AppNavigator {
    enum Destination: Equatable {
        case worker(WorkerScript)
        case zone(Zone)

        var tab: AppTab {
            switch self {
            case .worker: .workers
            case .zone: .domains
            }
        }
    }

    struct Request: Equatable {
        let destination: Destination
        let accountId: String
    }

    static let shared = AppNavigator()

    var pendingRequest: Request?

    func open(_ destination: Destination, accountId: String) {
        pendingRequest = Request(destination: destination, accountId: accountId)
    }
}
