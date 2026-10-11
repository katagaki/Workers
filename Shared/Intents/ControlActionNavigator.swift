import Foundation
import Observation

@Observable
final class ControlActionNavigator {
    enum Action: Sendable { case pause, underAttack, purge }
    struct Request: Identifiable {
        let id = UUID()
        let zone: ZoneEntity
        let action: Action
        var enabled = false
    }
    static let shared = ControlActionNavigator()
    var pendingRequest: Request?
}
