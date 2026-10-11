import Foundation

final class DemoZoneActions: @unchecked Sendable {
    static let shared = DemoZoneActions()
    private let lock = NSLock()
    private var underAttack: [String: String] = [:]
    private var paused: [String: Bool] = [:]

    func securityLevel(zoneId: String, method: String, body: [String: Any]?) -> [String: Any] {
        lock.withLock {
            if method == "PATCH" { underAttack[zoneId] = body?["value"] as? String }
            return DemoRouter.envelope(["value": underAttack[zoneId] ?? "essentially_off", "editable": true])
        }
    }

    func zone(_ zone: DemoData.DemoZone, method: String, body: [String: Any]?) -> [String: Any] {
        lock.withLock {
            if method == "PATCH", let value = body?["paused"] as? Bool { paused[zone.id] = value }
            var result = DemoResources.zone(zone)
            if let value = paused[zone.id] { result["paused"] = value }
            return DemoRouter.envelope(result)
        }
    }
}
