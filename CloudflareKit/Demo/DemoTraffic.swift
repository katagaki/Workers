import Foundation

enum DemoTraffic {
    struct Log {
        let level: String
        let message: String
    }

    struct Exception {
        let name: String
        let message: String
    }

    struct Event {
        let eventType: String
        let method: String?
        let url: String?
        let status: Int?
        let trigger: String
        let logs: [Log]
        let exception: Exception?

        var isError: Bool { exception != nil || (status ?? 0) >= 500 }

        var level: String {
            if isError { return "error" }
            if (status ?? 0) >= 400 { return "warn" }
            return logs.contains { $0.level == "log" } ? "log" : "info"
        }

        var summary: String {
            if let exception { return "\(exception.name): \(exception.message)" }
            return logs.last?.message ?? trigger
        }
    }

    static func event(scriptName: String, index: Int) -> Event {
        let templates = self.templates(for: scriptName)
        if index % 13 == 5, let failure = failure(for: scriptName) {
            return failure
        }
        return templates[index % templates.count]
    }

    private static func fetch(_ method: String, _ host: String, _ path: String, _ status: Int, _ logs: [Log], exception: Exception? = nil) -> Event {
        Event(eventType: "fetch", method: method, url: "https://\(host)\(path)", status: status, trigger: "\(method) \(path)", logs: logs, exception: exception)
    }

    private static func log(_ message: String) -> Log { Log(level: "log", message: message) }
    private static func warn(_ message: String) -> Log { Log(level: "warn", message: message) }
    private static func error(_ message: String) -> Log { Log(level: "error", message: message) }

    private static func templates(for scriptName: String) -> [Event] {
        switch scriptName {
        case "momotalk-compress":
            let host = "images.schale.gov.kv"
            return [
                fetch("GET", host, "/avatars/aris.png?width=256&format=webp", 200, [log("Resized 1024x1024 to 256x256 (webp, 18.4 KB)")]),
                fetch("GET", host, "/stickers/peroro.png?width=128", 200, [log("Served cached variant from R2 bucket originals")]),
                fetch("GET", host, "/avatars/hoshino.png?width=64&format=avif", 200, [log("Resized 1024x1024 to 64x64 (avif, 2.1 KB)")]),
                fetch("GET", host, "/banners/summer-festival.jpg?width=1280", 200, [log("Resized 3840x1600 to 1280x533 (webp, 96.2 KB)")]),
                fetch("GET", host, "/stickers/arona-wave.png?width=128", 404, [warn("R2 object not found: stickers/arona-wave.png")])
            ]
        case "momotalk-auth":
            let host = "momotalk.kv"
            return [
                fetch("POST", host, "/auth/login", 200, [log("Issued session for student 10024 (Millennium Science School)")]),
                fetch("GET", host, "/auth/session", 200, [log("Session valid, expires in 42 minutes")]),
                fetch("POST", host, "/auth/refresh", 200, [log("Refreshed access token for student 10031")]),
                fetch("POST", host, "/auth/logout", 204, [log("Revoked session for student 10017")]),
                fetch("POST", host, "/auth/login", 401, [warn("Invalid one-time code for student 10087 (attempt 2 of 5)")])
            ]
        case "momotalk-chats":
            let host = "chat.momotalk.kv"
            return [
                fetch("GET", host, "/rooms/game-development/ws", 101, [log("WebSocket upgraded, forwarded to ChatRoom game-development")]),
                fetch("POST", host, "/rooms/game-development/messages", 201, [log("Delivered message to 4 participants")]),
                fetch("GET", host, "/rooms/foreclosure-task-force/messages?before=1042", 200, [log("Loaded 50 messages from SQLite storage")]),
                fetch("GET", host, "/presence/10024", 200, [log("Student 10024 is online in 2 rooms")]),
                fetch("GET", host, "/rooms/veritas/messages", 403, [warn("Student 10031 is not a member of room veritas")])
            ]
        case "memorial-stream":
            let host = "hooks.millenium.edu.kv"
            return [
                fetch("POST", host, "/webhooks/momotalk", 202, [log("Verified signature"), log("Enqueued 3 messages to webhook-outbox")]),
                Event(eventType: "queue", method: nil, url: nil, status: nil, trigger: "webhook-outbox", logs: [log("Delivered batch of 10 messages to 3 receivers")], exception: nil),
                fetch("POST", host, "/webhooks/schedule", 202, [log("Enqueued 1 message to webhook-outbox")]),
                Event(eventType: "queue", method: nil, url: nil, status: nil, trigger: "webhook-outbox", logs: [warn("Retrying 2 messages after 503 from receiver")], exception: nil),
                fetch("POST", host, "/webhooks/momotalk", 401, [warn("Rejected webhook with invalid signature")])
            ]
        case "wildhunt-visitor-management":
            return [
                Event(eventType: "scheduled", method: nil, url: nil, status: nil, trigger: "*/30 * * * *", logs: [log("Checked in 4 visitors at the main gate"), log("Updated visitor roster in KV")], exception: nil),
                Event(eventType: "scheduled", method: nil, url: nil, status: nil, trigger: "*/30 * * * *", logs: [log("No pending visitor requests")], exception: nil),
                Event(eventType: "scheduled", method: nil, url: nil, status: nil, trigger: "0 3 * * *", logs: [log("Purged 12 expired visitor passes")], exception: nil)
            ]
        default:
            let host = "api.schale.gov.kv"
            return [
                fetch("GET", host, "/v1/students/10024", 200, [log("Cache hit for students:10024")]),
                fetch("GET", host, "/v1/students?club=game-development", 200, [log("Cache miss for students:club=game-development, fetching from origin")]),
                fetch("POST", host, "/v1/requests", 201, [log("Session verified by momotalk-auth"), log("Created request #4821 for Foreclosure Task Force")]),
                fetch("GET", host, "/v1/schedule/today", 200, [log("Cache hit for schedule:today")]),
                fetch("GET", host, "/health", 200, [log("Health check passed")]),
                fetch("GET", host, "/v1/students/99999", 404, [warn("No student found with id 99999")]),
                fetch("POST", host, "/v1/requests", 429, [warn("Rate limit exceeded for client sensei (120 requests per minute)")])
            ]
        }
    }

    private static func failure(for scriptName: String) -> Event? {
        switch scriptName {
        case "momotalk-compress":
            return fetch("GET", "images.schale.gov.kv", "/banners/kivotos-panorama.png?width=4096", 500, [error("Failed to decode source image")], exception: Exception(name: "RangeError", message: "Image dimensions exceed maximum of 12000px"))
        case "momotalk-auth":
            return fetch("POST", "momotalk.kv", "/auth/login", 500, [error("Failed to write session")], exception: Exception(name: "Error", message: "D1_ERROR: database is locked"))
        case "momotalk-chats":
            return fetch("POST", "chat.momotalk.kv", "/rooms/game-development/messages", 500, [error("ChatRoom game-development failed to persist message")], exception: Exception(name: "Error", message: "Durable Object reset because its code was updated"))
        case "memorial-stream":
            return Event(eventType: "queue", method: nil, url: nil, status: nil, trigger: "webhook-outbox", logs: [error("Receiver hooks.abydos.edu.kv returned 503 after 3 attempts")], exception: Exception(name: "Error", message: "Message retry limit reached, sent to dead letter queue"))
        case "wildhunt-visitor-management":
            return Event(eventType: "scheduled", method: nil, url: nil, status: nil, trigger: "*/30 * * * *", logs: [error("Visitor roster sync failed")], exception: Exception(name: "Error", message: "KV PUT failed: 429 Too Many Requests"))
        default:
            return fetch("POST", "api.schale.gov.kv", "/v1/requests", 500, [error("Upstream timed out after 3000ms")], exception: Exception(name: "Error", message: "Upstream request failed: 504 Gateway Timeout"))
        }
    }
}
