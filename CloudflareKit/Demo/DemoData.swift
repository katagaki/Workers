import Foundation

enum DemoData {
    static let accountId = "8d2c4f1e9a7b4c3d5e6f708192a3b4c5"

    struct Script {
        let name: String
        let baseRequests: Double
        let errorRate: Double
        let cpuTime: Double
        let handlers: [String]
        let modifiedHoursAgo: Double
    }

    static let scripts: [Script] = [
        Script(name: "schale-gateway", baseRequests: 4200, errorRate: 0.004, cpuTime: 2400, handlers: ["fetch"], modifiedHoursAgo: 3),
        Script(name: "momotalk-compress", baseRequests: 2600, errorRate: 0.001, cpuTime: 9800, handlers: ["fetch"], modifiedHoursAgo: 30),
        Script(name: "momotalk-auth", baseRequests: 1800, errorRate: 0.012, cpuTime: 1700, handlers: ["fetch"], modifiedHoursAgo: 52),
        Script(name: "momotalk-chats", baseRequests: 950, errorRate: 0.002, cpuTime: 1100, handlers: ["fetch"], modifiedHoursAgo: 120),
        Script(name: "memorial-stream", baseRequests: 420, errorRate: 0.03, cpuTime: 800, handlers: ["fetch", "queue"], modifiedHoursAgo: 260),
        Script(name: "wildhunt-visitor-management", baseRequests: 12, errorRate: 0, cpuTime: 5200, handlers: ["scheduled"], modifiedHoursAgo: 640)
    ]

    struct DemoZone {
        let id: String
        let name: String
        let status: String
        let plan: String
        let baseRequests: Double
    }

    static let zones: [DemoZone] = [
        DemoZone(id: "1a2b3c4d5e6f708192a3b4c5d6e7f801", name: "schale.gov.kv", status: "active", plan: "Pro Website", baseRequests: 6800),
        DemoZone(id: "2b3c4d5e6f708192a3b4c5d6e7f80912", name: "momotalk.kv", status: "active", plan: "Free Website", baseRequests: 2100),
        DemoZone(id: "3c4d5e6f708192a3b4c5d6e7f8091223", name: "millenium.edu.kv", status: "active", plan: "Business Website", baseRequests: 3900),
        DemoZone(id: "4d5e6f708192a3b4c5d6e7f809122334", name: "abydos.edu.kv", status: "pending", plan: "Free Website", baseRequests: 0)
    ]

    struct Namespace {
        let id: String
        let className: String
        let script: String
        let sqlite: Bool
        let baseRequests: Double
        let objectCount: Int
    }

    static let namespaces: [Namespace] = [
        Namespace(id: "a1b2c3d4e5f60718293a4b5c6d7e8f90", className: "ChatRoom", script: "momotalk-chats", sqlite: true, baseRequests: 780, objectCount: 64),
        Namespace(id: "b2c3d4e5f60718293a4b5c6d7e8f9001", className: "PresenceTracker", script: "momotalk-chats", sqlite: true, baseRequests: 310, objectCount: 12),
        Namespace(id: "c3d4e5f60718293a4b5c6d7e8f900112", className: "RateLimiter", script: "schale-gateway", sqlite: false, baseRequests: 1500, objectCount: 38),
        Namespace(id: "d4e5f60718293a4b5c6d7e8f90011223", className: "SessionStore", script: "momotalk-auth", sqlite: true, baseRequests: 640, objectCount: 120)
    ]

    static func hex(_ seed: Int, length: Int = 32) -> String {
        var value = UInt64(truncatingIfNeeded: seed &* 2654435761 &+ 97)
        var result = ""
        while result.count < length {
            value = value &* 6364136223846793005 &+ 1442695040888963407
            result += String(format: "%016llx", value)
        }
        return String(result.prefix(length))
    }

    static func stableHash(_ text: String) -> Int {
        text.unicodeScalars.reduce(5381) { ($0 &* 33) &+ Int($1.value) }
    }

    static func noise(_ seed: Int) -> Double {
        var value = UInt64(bitPattern: Int64(seed)) &+ 0x9E3779B97F4A7C15
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        value = value ^ (value >> 31)
        return Double(value >> 11) / Double(1 << 53)
    }

    static func daily(_ date: Date) -> Double {
        let hour = Double(Calendar(identifier: .gregorian).component(.hour, from: date))
        return 0.55 + 0.45 * sin((hour - 8) / 24 * 2 * .pi)
    }

    static func iso(_ date: Date) -> String {
        date.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: true))
    }

    static func ago(hours: Double) -> String {
        iso(Date.now.addingTimeInterval(-hours * 3600))
    }
}
